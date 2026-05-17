# Technical Innovation

## 1. Unified emergency stack (not a feature list)
Single codebase connects **victim triggers → idempotent sync → WebSocket command center → geospatial AI**. Most competitors implement one layer only.

## 2. Offline-first SOS with conflict resolution
- Local SQLite queue with retry/backoff
- Idempotent `POST /api/sync/sos` prevents duplicate incidents
- SMS encodes GPS + deep link for coordinators without app install
- BLE mesh/P2P relay prototype for device-to-device hop

## 3. Edge motion AI (privacy-preserving)
On-device signals: accelerometer patterns for **fall, crash, panic, inactivity** — verification UI before auto-SOS. No raw sensor upload required for detection.

## 4. Danger Zone Engine
- Grid-based geospatial scoring (crime + accident + reports)
- Public APIs: `/api/public/safety/route-safety`, heatmap, hotspots
- WebSocket `safety:alert` pushes to dashboard in real time
- Demo seed + Firestore for production reports

## 5. Real-time operations fabric
- WebSocket hub on same port as API (`/ws?key=`)
- Event types: `sos:new`, `sos:location`, `incident:status`, `responder:assigned`, `safety:alert`
- Hackathon demo orchestrator sequences full story in 9 seconds

## 6. Clean architecture (mobile)
Feature modules + providers (`sos`, `offline`, `safety`) — testable, swappable data sources.

## Stack
| Layer | Tech |
|-------|------|
| Mobile | Flutter, Provider |
| API | Node.js, Express |
| Realtime | ws |
| Data | Firebase Admin / Firestore |
| Dashboard | React, Vite, Recharts, Google Maps |
| Demo | Web preview + `demoSimulationService` |
