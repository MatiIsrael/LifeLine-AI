/// Lifecycle of an offline-queued emergency operation.
enum SyncStatus {
  pending,
  syncing,
  synced,
  smsSent,
  meshRelayed,
  failed,
}

extension SyncStatusX on SyncStatus {
  String get storageValue => name;

  static SyncStatus fromStorage(String? value) {
    return SyncStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => SyncStatus.pending,
    );
  }
}
