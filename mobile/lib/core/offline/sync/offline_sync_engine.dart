import "dart:async";

import "../../services/api_service.dart";
import "../cache/sos_queue_dao.dart";
import "../connectivity/connectivity_monitor.dart";
import "../models/connectivity_quality.dart";
import "../models/queued_sos_event.dart";
import "../models/sync_status.dart";
import "conflict_resolver.dart";
import "retry_policy.dart";

/// Retries queued SOS events when connectivity returns (weak-internet aware).
class OfflineSyncEngine {
  final SosQueueDao _queue = SosQueueDao();
  final ApiService _api = ApiService();
  final ConnectivityMonitor _connectivity;
  final ConflictResolver _resolver = ConflictResolver();

  StreamSubscription<ConnectivityQuality>? _connSub;
  Timer? _syncTimer;
  bool _syncing = false;

  OfflineSyncEngine(this._connectivity);

  void start() {
    _connSub = _connectivity.stream.listen((quality) {
      if (quality.canAttemptCloud) {
        syncPending();
      }
    });
    _syncTimer = Timer.periodic(const Duration(minutes: 2), (_) => syncPending());
    syncPending();
  }

  void stop() {
    _connSub?.cancel();
    _syncTimer?.cancel();
  }

  Future<int> syncPending() async {
    if (_syncing) return 0;
    if (!_connectivity.current.canAttemptCloud) return 0;

    _syncing = true;
    var synced = 0;

    try {
      final pending = await _queue.getPending();
      for (final event in pending) {
        if (!RetryPolicy.shouldRetry(event.retryCount)) continue;

        final due = event.lastRetryAt?.add(RetryPolicy.delayForAttempt(event.retryCount)) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        if (DateTime.now().isBefore(due)) continue;

        final ok = await _syncOne(event);
        if (ok) synced++;
      }
    } finally {
      _syncing = false;
    }
    return synced;
  }

  Future<bool> _syncOne(QueuedSosEvent event) async {
    try {
      await _queue.update(event.copyWith(status: SyncStatus.syncing));

      final response = await _api.post("/sync/sos", {
        "localId": event.localId,
        "version": event.version,
        "payload": event.payload,
        "serverEventId": event.serverEventId,
      });

      final resolved = _resolver.resolveAfterSync(local: event, serverResponse: response);
      await _queue.update(
        resolved.copyWith(
          status: SyncStatus.synced,
          lastRetryAt: DateTime.now(),
        ),
      );
      return true;
    } catch (_) {
      await _queue.update(
        event.copyWith(
          status: SyncStatus.failed,
          retryCount: event.retryCount + 1,
          lastRetryAt: DateTime.now(),
        ),
      );
      return false;
    }
  }

  Future<int> pendingCount() => _queue.pendingCount();
}
