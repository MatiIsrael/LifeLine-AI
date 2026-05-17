# AI Danger Zone Prediction

Smart-city safety layer for Lifeline AI.

## Features

- Crime hotspot prediction
- Accident-prone road analysis
- Unsafe area heatmaps
- Composite risk scoring (0–100)
- Predictive alerts by location & time

## Data sources

| Source | Collection |
|--------|------------|
| Historical incidents | `safety_incidents` Firestore |
| User reports | `safety_reports` |
| GPS patterns | `gps_patterns` |
| Time analysis | Night/weekend multipliers in engine |

## API

- `GET /api/public/safety/risk?lat=&lng=`
- `GET /api/public/safety/heatmap`
- `GET /api/public/safety/hotspots`
- `GET /api/public/safety/alerts`
- `POST /api/public/safety/route-safety`
- `POST /api/safety/reports` (authenticated)

Dashboard: `/api/dashboard/safety/*`

## Seed demo data

```bash
cd backend && npm run seed:safety
```
