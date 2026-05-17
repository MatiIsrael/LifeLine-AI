# Judge Presentation Flow (5 minutes)

| Time | Slide / Screen | What to say |
|------|----------------|---------------|
| 0:00 | Title — Lifeline AI | "Next-generation national emergency response infrastructure." |
| 0:30 | Problem | 4.5B people lack reliable emergency access in dead zones; 7–14 min average urban response vs 45+ rural. |
| 1:00 | Solution diagram (`home/index.html`) | Victim → Cloud → Responders; offline path parallel. |
| 1:30 | **Live demo** — preview | AI fall → SOS → tracking. |
| 2:30 | **Live demo** — dashboard | WebSocket incident → dispatch → map. |
| 3:15 | Risk AI view | Predictive danger zones, heatmaps, route safety. |
| 3:45 | Social impact (`SOCIAL_IMPACT.md`) | Rural equity, lives saved model, accessibility. |
| 4:15 | Tech innovation (`TECH_INNOVATION.md`) | Edge AI, offline-first, mesh, geospatial engine. |
| 4:35 | Business (`INVESTOR_PITCH.md` § market) | B2G + B2B2C, national contracts, SaaS command centers. |
| 4:50 | Ask | "We're seeking pilot partnerships with municipalities and EMS networks." |

## Judge Q&A cheat sheet

| Question | Answer |
|----------|--------|
| How is this different from 999 apps? | We combine **victim triggers + offline delivery + dispatcher OS + predictive safety** — not a single panic button. |
| What if there's no internet? | SMS fallback, local queue, BLE mesh relay, sync when online — built for rural Africa/Asia corridors. |
| Privacy? | Role-based dashboard keys, Firebase rules, minimal PII on broadcast, victim consent flows in production. |
| Is the AI real? | Motion detection runs on-device; danger zones use geospatial scoring + seeded/demo data; production uses aggregated reports. |
| Scale? | Stateless Node API, Firestore, regional shards, CDN for dashboard — see `SCALABILITY.md`. |
