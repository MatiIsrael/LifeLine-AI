import "dart:async";

import "package:firebase_auth/firebase_auth.dart";
import "package:geolocator/geolocator.dart";
import "package:uuid/uuid.dart";

import "../config/app_config.dart";
import "../models/emergency_contact.dart";
import "../models/trigger_source.dart";
import "../services/api_service.dart";
import "../services/firestore_service.dart";
import "../services/location_service.dart";
import "../services/storage/emergency_storage_service.dart";
import "cache/sos_queue_dao.dart";
import "connectivity/connectivity_monitor.dart";
import "mesh/peer_relay_service.dart";
import "models/connectivity_quality.dart";
import "models/offline_emergency_settings.dart";
import "models/queued_sos_event.dart";
import "models/sync_status.dart";
import "offline_settings_store.dart";
import "sms/sms_fallback_service.dart";
import "sync/offline_sync_engine.dart";

/// Offline-first emergency pipeline: queue → cloud → SMS → BLE mesh relay.
class OfflineEmergencyOrchestrator {
  OfflineEmergencyOrchestrator._();
  static final OfflineEmergencyOrchestrator instance = OfflineEmergencyOrchestrator._();

  final ConnectivityMonitor connectivity = ConnectivityMonitor();
  final SosQueueDao _queue = SosQueueDao();
  final ApiService _api = ApiService();
  final LocationService _location = LocationService();
  final SmsFallbackService _sms = SmsFallbackService();
  final PeerRelayService _peerRelay = PeerRelayService();
  final FirestoreService _firestore = FirestoreService();
  final EmergencyStorageService _storage = EmergencyStorageService();
  final OfflineSettingsStore _settingsStore = OfflineSettingsStore();
  final _uuid = const Uuid();

  late final OfflineSyncEngine syncEngine = OfflineSyncEngine(connectivity);

  OfflineEmergencySettings _settings = const OfflineEmergencySettings();
  StreamSubscription? _relaySub;
  StreamSubscription<Position>? _trackingSub;
  String? _trackingEventId;

  OfflineEmergencySettings get settings => _settings;

  Future<void> initialize() async {
    _settings = await _settingsStore.load();
    connectivity.start(probeInterval: const Duration(seconds: 20));
    syncEngine.start();
    await _peerRelay.start();

    _relaySub = _peerRelay.onRelayReceived.listen((packet) async {
      if (connectivity.current.canAttemptCloud) {
        await syncEngine.syncPending();
      }
    });
  }

  Future<void> updateSettings(OfflineEmergencySettings settings) async {
    _settings = settings;
    await _settingsStore.save(settings);
  }

  Future<String> triggerEmergency({
    required bool silent,
    required TriggerSource source,
    required bool recordAudio,
    String? audioPath,
    String? userName,
  }) async {
    final position = await _location.getCurrentPosition();
    final localId = _uuid.v4();
    final payload = {
      "latitude": position.latitude,
      "longitude": position.longitude,
      "address": "Unknown address",
      "silent": silent,
      "triggerType": source.apiValue,
      "recordAudio": recordAudio,
      "audioPath": audioPath,
    };

    final queued = QueuedSosEvent(
      localId: localId,
      payload: payload,
      status: SyncStatus.pending,
      version: 1,
      retryCount: 0,
      createdAt: DateTime.now(),
    );
    await _queue.insert(queued);

    final deferHeavy = _settings.weakInternetOptimization &&
        connectivity.current == ConnectivityQuality.weak;

    if (connectivity.current.canAttemptCloud) {
      try {
        final eventId = await _cloudTrigger(payload, deferAudio: deferHeavy);
        await _queue.update(
          queued.copyWith(
            serverEventId: eventId,
            status: SyncStatus.synced,
          ),
        );
        _startLiveTracking(eventId);

        if (recordAudio && audioPath != null && !deferHeavy && AppConfig.firebaseReady) {
          unawaited(_uploadAudio(eventId, audioPath));
        }

        return eventId;
      } catch (_) {
        // Continue to offline fallbacks below.
      }
    }

    await _deliverOfflineFallbacks(
      event: queued,
      position: position,
      userName: userName ?? "Lifeline user",
      triggerType: source.apiValue,
    );

    return localId;
  }

  Future<String> _cloudTrigger(
    Map<String, dynamic> payload, {
    required bool deferAudio,
  }) async {
    final body = Map<String, dynamic>.from(payload);
    if (deferAudio) body["recordAudio"] = false;

    final response = await _api.post("/sos/trigger", body);
    return response["eventId"] as String;
  }

  Future<void> _deliverOfflineFallbacks({
    required QueuedSosEvent event,
    required Position position,
    required String userName,
    required String triggerType,
  }) async {
    var updated = event;

    if (_settings.smsFallbackEnabled && connectivity.current.preferSmsFallback) {
      try {
        final contacts = await _firestore.getContacts();
        final sent = await _sms.sendEmergencySms(
          contacts: contacts,
          latitude: position.latitude,
          longitude: position.longitude,
          userName: userName,
          triggerType: triggerType,
        );
        if (sent) {
          updated = updated.copyWith(
            smsSent: true,
            status: SyncStatus.smsSent,
          );
          await _queue.update(updated);
        }
      } catch (_) {}
    }

    if (_settings.meshRelayEnabled) {
      try {
        await _peerRelay.relayEmergency(
          localEventId: event.localId,
          latitude: position.latitude,
          longitude: position.longitude,
          message: "SOS $triggerType — relay requested",
        );
        updated = updated.copyWith(meshRelayed: true, status: SyncStatus.meshRelayed);
        await _queue.update(updated);
      } catch (_) {}
    }

    if (connectivity.current.canAttemptCloud) {
      unawaited(syncEngine.syncPending());
    }
  }

  Future<void> _uploadAudio(String eventId, String audioPath) async {
    try {
      final audioUrl = await _storage.uploadEmergencyAudio(
        eventId: eventId,
        localPath: audioPath,
      );
      if (audioUrl != null) {
        await _api.post("/sos/$eventId/audio", {"audioUrl": audioUrl});
      }
    } catch (_) {}
  }

  void _startLiveTracking(String eventId) {
    _trackingEventId = eventId;
    _trackingSub?.cancel();
    _trackingSub = _location.positionStream().listen((position) async {
      if (!connectivity.current.canAttemptCloud) return;
      try {
        await _api.post("/sos/$eventId/location", {
          "latitude": position.latitude,
          "longitude": position.longitude,
          "speed": position.speed,
          "heading": position.heading,
        });
      } catch (_) {}
    });
  }

  Future<void> resolveEmergency(String eventOrLocalId, {String notes = ""}) async {
    _trackingSub?.cancel();
    _trackingEventId = null;

    final queued = await _queue.getByLocalId(eventOrLocalId);
    final serverId = queued?.serverEventId ?? eventOrLocalId;

    if (!connectivity.current.canAttemptCloud) return;

    try {
      await _api.post("/sos/$serverId/resolve", {"notes": notes});
    } catch (_) {}
  }

  Future<int> pendingQueueCount() => _queue.pendingCount();

  Future<String?> displayName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    try {
      final profile = await _firestore.getProfile();
      return profile?.fullName ?? user.email;
    } catch (_) {
      return user.email;
    }
  }

  void dispose() {
    _relaySub?.cancel();
    _trackingSub?.cancel();
    connectivity.dispose();
    syncEngine.stop();
    _peerRelay.dispose();
  }
}
