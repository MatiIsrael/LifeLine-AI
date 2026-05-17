# Lifeline AI MVP

Lifeline AI is an emergency response app built with Flutter + Firebase + Node.js.

**Simple overview page** (explains the system in plain language):

```bash
npx serve home -l 4000
```

→ http://localhost:4000

## Hackathon & demo day

Full presentation kit in **`hackathon/`**:

| Asset | Purpose |
|-------|---------|
| [hackathon/README.md](hackathon/README.md) | Quick-start for judges |
| [hackathon/pitch-deck.html](hackathon/pitch-deck.html) | Browser slides (← → to navigate) |
| [DEMO_SCRIPT.md](hackathon/DEMO_SCRIPT.md) | 3-minute live demo script |
| [JUDGE_FLOW.md](hackathon/JUDGE_FLOW.md) | 5-minute judging flow |
| [ELEVATOR_PITCH.md](hackathon/ELEVATOR_PITCH.md) | 60-second pitch |
| [INVESTOR_PITCH.md](hackathon/INVESTOR_PITCH.md) | Investor deck structure |
| [ARCHITECTURE.md](hackathon/ARCHITECTURE.md) | Mermaid system diagrams |

**Live demo:** On mobile preview click **Run Hackathon Demo**; on dashboard click **Launch live demo** (requires backend).

```bash
cd backend && npm run dev
cd dashboard && npm run dev
npx serve preview -l 3000
npx serve home -l 4000
npx serve hackathon -l 5000
```

Tagline: *Next-generation national emergency response infrastructure.*

## 1) Architecture

### High-level flow

1. User authenticates with Firebase Authentication (email/password).
2. Flutter app stores emergency profile + trusted contacts in Firestore.
3. User taps SOS.
4. App captures live GPS and calls Node.js API with Firebase ID token.
5. Node.js verifies token, writes emergency event, and sends FCM alerts.
6. Contacts receive push notification and can open live tracking view.
7. Location updates stream to Firestore in realtime.

### Tech stack

- `mobile/`: Flutter app (Provider state management, Google Maps)
- `backend/`: Node.js Express API with Firebase Admin SDK
- `firebase/`: Firestore and Storage security rules

### Offline & rural emergency (new)

Designed for **low connectivity** and **no internet** scenarios:

| Capability | Description |
|------------|-------------|
| **Offline-first queue** | SQLite-backed SOS queue; never drops an alert |
| **SMS fallback** | Sends GPS + Google Maps link to trusted contacts via SMS |
| **Auto cloud sync** | Retries with exponential backoff when signal returns |
| **Weak internet mode** | Defers heavy uploads; prioritizes alert delivery |
| **BLE mesh relay** | Peer-to-peer relay through nearby devices (3-hop limit) |
| **Conflict resolution** | Idempotent `localId` sync via `POST /api/sync/sos` |

See `mobile/lib/core/offline/OFFLINE.md` for architecture details.

### Emergency command dashboard (new)

Web operations center for **hospitals, ambulance, police, and coordinators**:

| Capability | Stack |
|------------|--------|
| Live map, SOS feed, victim tracking | React + Google Maps |
| Real-time alerts | WebSockets (`/ws`) |
| Responder dispatch & route optimization | Node.js + Firestore |
| Analytics & incident workflow | Recharts + REST API |

```bash
cd backend && npm install && npm run dev
cd dashboard && npm install && npm run dev
```

Open http://localhost:5173 — see `dashboard/README.md`.

### AI danger zone prediction (new)

Smart-city safety intelligence:

| Feature | Description |
|---------|-------------|
| **Crime hotspots** | Gaussian incident model over historical data |
| **Accident corridors** | Weighted accident-prone road scoring |
| **Heatmaps** | Grid-based unsafe area visualization |
| **Risk score** | 0–100 composite with time-of-day factors |
| **Route safety** | Sampled path analysis + safer detour suggestion |
| **Predictive alerts** | Proximity + night-risk notifications |

See `mobile/lib/core/safety/SAFETY.md` and `GET /api/public/safety/heatmap`.

---

## 2) Folder structure

```txt
Lifeline AI/
  mobile/
    lib/
      core/
      features/
      shared/
  backend/
    src/
      config/
      middleware/
      routes/
      services/
  firebase/
```

---

## 3) Firestore schema

### `users/{uid}`
- `fullName: string`
- `email: string`
- `phoneNumber: string`
- `bloodGroup: string`
- `medicalNotes: string`
- `photoUrl: string?`
- `createdAt: timestamp`
- `updatedAt: timestamp`

### `users/{uid}/contacts/{contactId}`
- `name: string`
- `phoneNumber: string`
- `relationship: string`
- `fcmTokens: string[]`
- `createdAt: timestamp`

### `emergencies/{eventId}`
- `uid: string`
- `status: "active" | "resolved"`
- `latitude: number`
- `longitude: number`
- `address: string`
- `silent: boolean`
- `triggerType: string` (`manual`, `shake`, `power_button`, `voice`, `calculator`, `background`)
- `recordAudio: boolean`
- `audioPath: string?`
- `audioUrl: string?`
- `triggeredAt: timestamp`
- `resolvedAt: timestamp?`
- `notes: string?`
- `contactIds: string[]`

### `emergencies/{eventId}/locations/{locationId}`
- `latitude: number`
- `longitude: number`
- `speed: number`
- `heading: number`
- `recordedAt: timestamp`

### `deviceTokens/{uid}`
- `tokens: string[]`
- `updatedAt: timestamp`

---

## 4) Backend API

All routes require `Authorization: Bearer <firebase-id-token>`.

- `POST /api/profile` -> create/update emergency profile
- `GET /api/profile` -> fetch profile + contacts
- `POST /api/profile/contact` -> add emergency contact
- `POST /api/sos/trigger` -> trigger SOS and notify contacts
- `POST /api/sos/:eventId/location` -> push live location updates
- `POST /api/sos/:eventId/resolve` -> resolve active emergency
- `GET /api/history` -> get emergency history
- `POST /api/device-token` -> register current user device token

---

## 5) Full setup

See **[SETUP.md](SETUP.md)** for complete Firebase, Flutter, Maps, and contact-linking instructions.

## 6) Quick start

1. Create Firebase project.
2. Enable Authentication (Email/Password).
3. Create Firestore database.
4. Enable Cloud Messaging.
5. Add Android/iOS apps and download platform Firebase config files:
   - Android: `mobile/android/app/google-services.json`
   - iOS: `mobile/ios/Runner/GoogleService-Info.plist`
6. Generate service account key and set:
   - `backend/.env` -> `GOOGLE_APPLICATION_CREDENTIALS=...`
7. Deploy rules in `firebase/`.
8. Run backend:
   - `cd backend && npm install && npm run dev`
9. Run Flutter app:
   - `cd mobile && flutter pub get && flutter run`

---

## 6) Security

- Firebase ID tokens are verified server-side in middleware.
- Firestore rules ensure users can only access their own data.
- Emergency events are write-protected by ownership.
- Device tokens are scoped by authenticated user.

---

## 7) Advanced emergency triggers (mobile)

- **Silent SOS mode** — hidden activation without UI navigation
- **Shake detection** — accelerometer peaks with sensitivity slider
- **Volume button (3 presses)** — Opens full emergency help UI (countdown, location, contacts, type)
- **Power button (3 presses)** — Android native screen-off pattern detection (optional)
- **Voice activation** — configurable emergency phrase
- **Fake calculator disguise** — secret code triggers SOS
- **Countdown cancellation** — 3–10s cancel window before alert
- **Background foreground service** — shake monitoring while app is closed (Android)
- **Optional audio recording** — evidence capture on trigger

Settings: `mobile/lib/features/settings/emergency_settings_screen.dart`

---

## 8) AI motion detection (edge)

- **Fall detection** — free-fall + impact pattern
- **Car crash detection** — high-G impact + stillness
- **Panic movement** — erratic gyro + repeated peaks
- **Abnormal movement** — sudden jerk analysis
- **Unconscious inactivity** — no motion after impact
- **Verification popup** — user must respond or SOS auto-sends
- **TensorFlow Lite ready** — hook in `tflite_motion_classifier.dart`

Architecture: `mobile/lib/core/motion_ai/MOTION_AI.md`

---

## 9) MVP capabilities included

- User registration/login
- Emergency profile setup
- One-tap SOS
- Live GPS sharing
- Emergency contact alerts (FCM)
- Realtime map tracking
- Emergency history
- Push notifications
- Dark mode first design
- Clean reusable architecture
