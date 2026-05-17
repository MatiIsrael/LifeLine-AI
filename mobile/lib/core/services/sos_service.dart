import "dart:async";

import "../config/app_config.dart";
import "../models/trigger_source.dart";
import "../offline/offline_emergency_orchestrator.dart";
import "api_service.dart";
import "storage/emergency_storage_service.dart";

/// SOS delivery — delegates to offline-first orchestrator for rural resilience.
class SosService {
  final OfflineEmergencyOrchestrator _offline = OfflineEmergencyOrchestrator.instance;
  final ApiService _apiService = ApiService();
  final EmergencyStorageService _storageService = EmergencyStorageService();

  Future<String> triggerSos({
    bool silent = false,
    TriggerSource source = TriggerSource.manual,
    bool recordAudio = false,
    String? audioPath,
  }) async {
    final userName = await _offline.displayName();
    return _offline.triggerEmergency(
      silent: silent,
      source: source,
      recordAudio: recordAudio,
      audioPath: audioPath,
      userName: userName,
    );
  }

  Future<void> resolveSos(String eventId, {String notes = ""}) async {
    await _offline.resolveEmergency(eventId, notes: notes);
  }

  Future<List<Map<String, dynamic>>> fetchHistory() async {
    if (!_offline.connectivity.current.canAttemptCloud) {
      final queued = await _offline.pendingQueueCount();
      if (queued > 0) {
        return [
          {
            "eventId": "offline-queue",
            "status": "pending_sync",
            "message": "$queued emergency alert(s) waiting to sync",
          },
        ];
      }
    }

    final response = await _apiService.get("/history");
    final history = response["history"] as List<dynamic>? ?? [];
    return history.cast<Map<String, dynamic>>();
  }

  Future<void> uploadDeferredAudio({
    required String eventId,
    required String audioPath,
  }) async {
    if (!AppConfig.firebaseReady) return;
    try {
      final audioUrl = await _storageService.uploadEmergencyAudio(
        eventId: eventId,
        localPath: audioPath,
      );
      if (audioUrl != null) {
        await _apiService.post("/sos/$eventId/audio", {"audioUrl": audioUrl});
      }
    } catch (_) {}
  }

  void dispose() {
    // Orchestrator lifecycle is app-scoped via OfflineProvider.
  }
}
