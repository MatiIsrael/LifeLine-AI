# Lifeline AI — Emergency Command Dashboard

Web-based operations center for hospitals, ambulance services, police, and emergency coordinators.

## Features

- **Live emergency map** (Google Maps) with SOS markers and responder positions
- **Incoming SOS feed** with real-time WebSocket updates
- **Victim tracking** via location trail polylines
- **Route optimization** — nearest available responder + ETA
- **Incident status workflow** — incoming → dispatched → en route → on scene → resolved
- **Emergency analytics** — 24h volume chart and status breakdown
- **Responder management** — dispatch ambulance, police, hospital units
- **Real-time notifications** — critical alerts over WebSocket

## Quick start

### 1. Backend (port 8080)

```bash
cd backend
npm install
# Set GOOGLE_APPLICATION_CREDENTIALS in .env
npm run seed:responders   # optional: seed demo responders
npm run dev
```

### 2. Dashboard (port 5173)

```bash
cd dashboard
npm install
cp .env.example .env
# Add VITE_GOOGLE_MAPS_API_KEY for live map
npm run dev
```

Open http://localhost:5173

**Default API key:** `lifeline-dashboard-dev` (must match `DASHBOARD_API_KEY` in backend `.env`)

## Environment

| Variable | Description |
|----------|-------------|
| `VITE_API_BASE` | Backend URL (default proxy to :8080) |
| `VITE_DASHBOARD_KEY` | Dashboard API key |
| `VITE_GOOGLE_MAPS_API_KEY` | Google Maps JavaScript API key |
| `DASHBOARD_API_KEY` | Backend-side key for `/api/dashboard` and WebSocket |

## API

- `GET /api/dashboard/incidents`
- `GET /api/dashboard/incidents/:id`
- `PATCH /api/dashboard/incidents/:id/status`
- `POST /api/dashboard/incidents/:id/assign`
- `POST /api/dashboard/incidents/:id/optimize-route`
- `GET /api/dashboard/responders`
- `GET /api/dashboard/analytics`
- `WS /ws?key=YOUR_DASHBOARD_KEY`

## Operator roles

Login screen supports role selection (coordinator, hospital, ambulance, police) for UI context. Production deployments should use Firebase Auth custom claims plus `verifyDashboardAccess`.
