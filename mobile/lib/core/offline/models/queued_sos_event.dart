import "dart:convert";

import "sync_status.dart";

/// Locally persisted SOS event awaiting cloud sync / fallback delivery.
class QueuedSosEvent {
  final String localId;
  final String? serverEventId;
  final Map<String, dynamic> payload;
  final SyncStatus status;
  final int version;
  final int retryCount;
  final DateTime createdAt;
  final DateTime? lastRetryAt;
  final bool smsSent;
  final bool meshRelayed;
  final String? conflictResolution;

  QueuedSosEvent({
    required this.localId,
    this.serverEventId,
    required this.payload,
    required this.status,
    required this.version,
    required this.retryCount,
    required this.createdAt,
    this.lastRetryAt,
    this.smsSent = false,
    this.meshRelayed = false,
    this.conflictResolution,
  });

  String get payloadJson => jsonEncode(payload);

  QueuedSosEvent copyWith({
    String? serverEventId,
    SyncStatus? status,
    int? version,
    int? retryCount,
    DateTime? lastRetryAt,
    bool? smsSent,
    bool? meshRelayed,
    String? conflictResolution,
  }) {
    return QueuedSosEvent(
      localId: localId,
      serverEventId: serverEventId ?? this.serverEventId,
      payload: payload,
      status: status ?? this.status,
      version: version ?? this.version,
      retryCount: retryCount ?? this.retryCount,
      createdAt: createdAt,
      lastRetryAt: lastRetryAt ?? this.lastRetryAt,
      smsSent: smsSent ?? this.smsSent,
      meshRelayed: meshRelayed ?? this.meshRelayed,
      conflictResolution: conflictResolution ?? this.conflictResolution,
    );
  }

  factory QueuedSosEvent.fromMap(Map<String, dynamic> map) {
    return QueuedSosEvent(
      localId: map["local_id"] as String,
      serverEventId: map["server_event_id"] as String?,
      payload: jsonDecode(map["payload_json"] as String) as Map<String, dynamic>,
      status: SyncStatusX.fromStorage(map["status"] as String?),
      version: map["version"] as int? ?? 1,
      retryCount: map["retry_count"] as int? ?? 0,
      createdAt: DateTime.parse(map["created_at"] as String),
      lastRetryAt: map["last_retry_at"] != null
          ? DateTime.parse(map["last_retry_at"] as String)
          : null,
      smsSent: (map["sms_sent"] as int? ?? 0) == 1,
      meshRelayed: (map["mesh_relayed"] as int? ?? 0) == 1,
      conflictResolution: map["conflict_resolution"] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        "local_id": localId,
        "server_event_id": serverEventId,
        "payload_json": payloadJson,
        "status": status.storageValue,
        "version": version,
        "retry_count": retryCount,
        "created_at": createdAt.toIso8601String(),
        "last_retry_at": lastRetryAt?.toIso8601String(),
        "sms_sent": smsSent ? 1 : 0,
        "mesh_relayed": meshRelayed ? 1 : 0,
        "conflict_resolution": conflictResolution,
      };
}
