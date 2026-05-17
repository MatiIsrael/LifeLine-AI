import "package:sqflite/sqflite.dart";

import "../models/queued_sos_event.dart";
import "../models/sync_status.dart";
import "offline_database.dart";

/// Data access for the offline SOS queue.
class SosQueueDao {
  Future<Database> get _db => OfflineDatabase.instance();

  Future<void> insert(QueuedSosEvent event) async {
    final db = await _db;
    await db.insert("sos_queue", event.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> update(QueuedSosEvent event) async {
    final db = await _db;
    await db.update("sos_queue", event.toMap(), where: "local_id = ?", whereArgs: [event.localId]);
  }

  Future<QueuedSosEvent?> getByLocalId(String localId) async {
    final db = await _db;
    final rows = await db.query("sos_queue", where: "local_id = ?", whereArgs: [localId], limit: 1);
    if (rows.isEmpty) return null;
    return QueuedSosEvent.fromMap(rows.first);
  }

  Future<List<QueuedSosEvent>> getPending() async {
    final db = await _db;
    final rows = await db.query(
      "sos_queue",
      where: "status IN (?, ?, ?)",
      whereArgs: [
        SyncStatus.pending.storageValue,
        SyncStatus.failed.storageValue,
        SyncStatus.smsSent.storageValue,
      ],
      orderBy: "created_at ASC",
    );
    return rows.map(QueuedSosEvent.fromMap).toList();
  }

  Future<List<QueuedSosEvent>> getAll() async {
    final db = await _db;
    final rows = await db.query("sos_queue", orderBy: "created_at DESC");
    return rows.map(QueuedSosEvent.fromMap).toList();
  }

  Future<int> pendingCount() async {
    final pending = await getPending();
    return pending.length;
  }
}
