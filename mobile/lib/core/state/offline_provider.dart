import "package:flutter/foundation.dart";

import "../offline/models/connectivity_quality.dart";
import "../offline/models/offline_emergency_settings.dart";
import "../offline/offline_emergency_orchestrator.dart";

class OfflineProvider extends ChangeNotifier {
  final OfflineEmergencyOrchestrator _orchestrator = OfflineEmergencyOrchestrator.instance;

  ConnectivityQuality _quality = ConnectivityQuality.offline;
  int _pendingCount = 0;
  bool _initialized = false;

  ConnectivityQuality get quality => _quality;
  int get pendingCount => _pendingCount;
  bool get initialized => _initialized;
  OfflineEmergencySettings get settings => _orchestrator.settings;

  bool get isOffline => _quality == ConnectivityQuality.offline;
  bool get isWeak => _quality == ConnectivityQuality.weak;

  String get statusLabel {
    switch (_quality) {
      case ConnectivityQuality.offline:
        return _pendingCount > 0
            ? "Offline — $_pendingCount SOS queued (SMS/mesh active)"
            : "Offline — SMS & mesh relay ready";
      case ConnectivityQuality.weak:
        return "Weak signal — compact sync, retries active";
      case ConnectivityQuality.online:
        return _pendingCount > 0 ? "Syncing $_pendingCount queued alert(s)…" : "Connected";
    }
  }

  Future<void> initialize() async {
    if (_initialized) return;
    await _orchestrator.initialize();
    _orchestrator.connectivity.stream.listen((q) {
      _quality = q;
      notifyListeners();
      _refreshPending();
    });
    _quality = _orchestrator.connectivity.current;
    await _refreshPending();
    _initialized = true;
    notifyListeners();
  }

  Future<void> updateSettings(OfflineEmergencySettings settings) async {
    await _orchestrator.updateSettings(settings);
    notifyListeners();
  }

  Future<void> syncNow() async {
    await _orchestrator.syncEngine.syncPending();
    await _refreshPending();
  }

  Future<void> _refreshPending() async {
    _pendingCount = await _orchestrator.pendingQueueCount();
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
