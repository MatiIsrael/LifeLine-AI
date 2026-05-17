import "../models/queued_sos_event.dart";

/// Resolves client/server SOS conflicts for offline-first sync.
class ConflictResolver {
  /// Merges server response into local queued event after sync.
  QueuedSosEvent resolveAfterSync({
    required QueuedSosEvent local,
    required Map<String, dynamic> serverResponse,
  }) {
    final serverEventId = serverResponse["eventId"] as String?;
    final serverVersion = serverResponse["serverVersion"] as int? ?? local.version;
    final resolution = serverResponse["conflictResolution"] as String? ?? "server_accepted";

    return local.copyWith(
      serverEventId: serverEventId ?? local.serverEventId,
      version: serverVersion,
      conflictResolution: resolution,
    );
  }

  /// When server reports duplicate localId, adopt existing server event.
  bool isDuplicateConflict(Map<String, dynamic> serverResponse) {
    return serverResponse["conflictResolution"] == "duplicate_local_id";
  }
}
