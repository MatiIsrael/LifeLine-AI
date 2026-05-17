import "package:path/path.dart";
import "package:sqflite/sqflite.dart";

/// SQLite store for offline SOS queue and relay deduplication cache.
class OfflineDatabase {
  static Database? _db;

  static Future<Database> instance() async {
    if (_db != null) return _db!;
    final base = await getDatabasesPath();
    final path = join(base, "lifeline_offline.db");
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute("""
          CREATE TABLE sos_queue (
            local_id TEXT PRIMARY KEY,
            server_event_id TEXT,
            payload_json TEXT NOT NULL,
            status TEXT NOT NULL,
            version INTEGER NOT NULL,
            retry_count INTEGER NOT NULL,
            created_at TEXT NOT NULL,
            last_retry_at TEXT,
            sms_sent INTEGER NOT NULL,
            mesh_relayed INTEGER NOT NULL,
            conflict_resolution TEXT
          )
        """);
        await db.execute("""
          CREATE TABLE relay_seen (
            packet_id TEXT PRIMARY KEY,
            received_at TEXT NOT NULL
          )
        """);
        await db.execute(
          "CREATE INDEX idx_sos_queue_status ON sos_queue(status)",
        );
      },
    );
    return _db!;
  }
}
