# Offline Emergency Communication

Rural and low-connectivity architecture for Lifeline AI.

## Pipeline (offline-first)

```
SOS trigger
    → SQLite queue (localId, payload, version)
    → Cloud API (if online/weak + health OK)
    → SMS fallback (GPS + maps link to trusted contacts)
    → BLE peer relay (hop-limited mesh, max 3 hops)
    → Sync engine retries cloud when connectivity returns
```

## Components

| Module | Role |
|--------|------|
| `offline_emergency_orchestrator.dart` | Coordinates queue, cloud, SMS, mesh |
| `connectivity/connectivity_monitor.dart` | offline / weak / online via interface + `/health` RTT |
| `cache/offline_database.dart` | SQLite `sos_queue`, `relay_seen` |
| `sync/offline_sync_engine.dart` | Exponential backoff retry to `POST /api/sync/sos` |
| `sync/conflict_resolver.dart` | Merges `localId` duplicates with server |
| `sms/sms_fallback_service.dart` | SMS intent with coordinates |
| `mesh/peer_relay_service.dart` | P2P relay + dedup cache |
| `mesh/bluetooth_mesh_service.dart` | BLE GATT scan/connect relay |

## When internet fails

1. Event is **queued** immediately (never lost).
2. **SMS** opens with GPS coordinates for each trusted contact phone.
3. **Mesh relay** broadcasts to nearby Lifeline devices; relays re-forward up to 3 hops.
4. **Sync engine** polls every 2 minutes and on connectivity change; up to 12 retries with backoff.

## Weak internet

- Health probe RTT &gt; 2.5s → `ConnectivityQuality.weak`
- Audio upload deferred; SOS payload sent without blocking on heavy uploads.

## Backend

- `POST /api/sync/sos` — idempotent sync by `localId`
- Firestore `offline_sync/{uid}_{localId}` maps client → server `eventId`

## Settings (Emergency triggers screen)

- Offline-first SOS
- SMS fallback
- Bluetooth mesh relay
- Weak internet optimization

## Permissions (Android)

`SEND_SMS`, `BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT`, `BLUETOOTH_ADVERTISE`, location.

## Production notes

- BLE relay requires peer devices running Lifeline with mesh enabled and compatible GATT service.
- SMS uses system intent; user may need to confirm send on some OEMs.
- For carrier-grade SMS without UI, integrate Twilio/MessageBird on backend when sync succeeds.
