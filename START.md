# Start Lifeline AI (one command)

## Windows

```powershell
cd "c:\Users\hp\Desktop\LifeLine AI"
.\scripts\start-all.ps1
```

This will:

1. Create `backend/.env` and `dashboard/.env` if missing
2. Install npm packages (first run only)
3. Start backend, dashboard, mobile preview, home page, pitch deck
4. Open Chrome tabs

## URLs

| Service | URL |
|---------|-----|
| Home (SOS alerts) | http://localhost:4000 |
| Mobile app demo | http://localhost:3000 |
| Command center | http://localhost:5173 |
| Pitch deck | http://localhost:5000/pitch-deck.html |
| API | http://localhost:8080/health |

**Dashboard key:** `lifeline-dashboard-dev`

## Firebase (optional)

Works in **demo mode** without Firebase. For production:

1. Add `backend/serviceAccountKey.json` from Firebase Console
2. Run `flutterfire configure` in `mobile/`

See [SETUP.md](SETUP.md) for full details.
