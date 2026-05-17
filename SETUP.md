# Lifeline AI — Complete Setup Guide

## 1) Prerequisites

- Node.js 18+
- Flutter 3.22+ (`flutter doctor`)
- Firebase project
- Android Studio (for emulator/device)
- Google Maps API key (for live map)

## 2) Firebase

1. Create project at https://console.firebase.google.com
2. Enable **Authentication** → Email/Password
3. Enable **Firestore**, **Cloud Messaging**, **Storage**
4. Download service account JSON → save as `backend/serviceAccountKey.json`
5. In `backend/.env`:
   ```
   PORT=8080
   GOOGLE_APPLICATION_CREDENTIALS=./serviceAccountKey.json
   ```

### Flutter Firebase config

```bash
cd mobile
dart pub global activate flutterfire_cli
flutterfire configure
```

This updates `lib/core/services/firebase_options.dart` and adds platform config files.

## 3) Backend

```bash
cd backend
npm install
npm run dev
```

Health check: http://localhost:8080/health

## 4) Mobile app

```bash
cd mobile
flutter pub get
flutter run
```

### API URL (physical device)

Edit `lib/core/services/app_constants.dart`:

- Emulator: `http://10.0.2.2:8080/api`
- Physical device: `http://<YOUR_PC_LAN_IP>:8080/api`

### Google Maps (Android)

Add to `android/app/src/main/AndroidManifest.xml` inside `<application>`:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_MAPS_API_KEY"/>
```

## 5) Emergency contacts + push

Trusted contacts must:

1. Register in Lifeline AI with the same email you enter in profile setup
2. Be linked via **Contact Lifeline email** field

SOS alerts are sent via FCM to linked `contactUid` values.

## 6) Advanced triggers

Open **Trigger settings** (tune icon) on home screen:

- Silent SOS, shake, voice, power button (3×), calculator disguise
- Countdown cancellation (3–10 seconds)
- Background monitoring (Android foreground service)
- Optional audio recording (uploaded to Firebase Storage)

## 7) Quick UI preview (no Flutter)

```bash
npx serve preview -l 3000
```

Open http://localhost:3000

## 8) Deploy Firestore rules

```bash
firebase deploy --only firestore:rules,storage
```

(From project root with Firebase CLI initialized.)
