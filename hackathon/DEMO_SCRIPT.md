# Lifeline AI — Live Demo Script (3 minutes)

**Before you start:** Backend `:8080`, Dashboard `:5173`, Preview `:3000`. Open dashboard in a second monitor or split screen.

---

## Act 1 — The problem (20 sec)

> "Every year, millions of emergencies happen where victims cannot reach help in time — especially in rural areas with no signal. Lifeline AI is **national emergency response infrastructure** that works when networks don't."

---

## Act 2 — Victim side (60 sec)

1. Open **http://localhost:3000** (mobile preview).
2. Say: *"This is the victim app — one tap SOS, but also invisible triggers."*
3. Click **▶ Run Hackathon Demo** (top bar) OR press **V** three times quickly.
4. Narrate the sequence:
   - *"AI motion engine detects a fall — user gets 3 seconds to cancel."*
   - Countdown → **Send alerts now**.
   - Tracking screen: *"GPS, contacts, SMS fallback, offline queue, Bluetooth mesh relay."*
5. Optional: open **Calculator** → type secret `911` → hidden SOS.

---

## Act 3 — Command center (60 sec)

1. Switch to **http://localhost:5173** — login key: `lifeline-dashboard-dev`.
2. Point to **WS LIVE** and **Active** counter.
3. Click **▶ Launch live demo** if victim demo didn't fire backend.
4. Narrate:
   - New incident appears in feed + map (WebSocket).
   - Select victim → assign **Metro Ambulance Unit 7**.
   - *"Dispatchers see live GPS drift and ETA."*

---

## Act 4 — AI safety layer (40 sec)

1. Toggle **Risk AI view** + **Heatmap ON**.
2. Say: *"We predict danger zones — crime hotspots, accident corridors — and warn victims before they enter high-risk paths."*
3. Show risk score panel and route safety (if time).

---

## Act 5 — Close (20 sec)

> "Victim app + offline rural resilience + national command center + predictive safety AI — one platform. We're building the **operating system for emergency response**."

**Backup:** If backend is down, dashboard and preview run in **demo mode** with sample data.
