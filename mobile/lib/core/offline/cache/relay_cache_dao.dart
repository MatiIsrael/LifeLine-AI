import "package:sqflite/sqflite.dart";

import "offline_database.dart";

/// Prevents processing duplicate mesh relay packets.
class RelayCacheDao {
  Future<Database> get _db => OfflineDatabase.instance();

  Future<bool> hasSeen(String packetId) async {
    final db = await _db;
    final rows = await db.query("relay_seen", where: "packet_id = ?", whereArgs: [packetId], limit: 1);
    return rows.isNotEmpty;
  }

  Future<void> markSeen(String packetId) async {
    final db = await _db;
    await db.insert(
      "relay_seen",
      {"packet_id": packetId, "received_at": DateTime.now().toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// Purge entries older than 24h to limit storage.
  Future<void> purgeOld() async {
    final db = await _db;
    final cutoff = DateTime.now().subtract(const Duration(hours: 24)).toIso8601String();
    await db.delete("relay_seen", where: "received_at < ?", whereArgs: [cutoff]);
  }
}
