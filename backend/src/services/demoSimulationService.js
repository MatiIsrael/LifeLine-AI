import { broadcast } from "../realtime/realtimeHub.js";
import { notifySosTriggered } from "./dashboardService.js";
import { broadcastSafetyAlert } from "./dangerZoneEngine.js";

const SCENARIOS = {
  ruralSos: {
    victimName: "Amina Okoye",
    latitude: 51.508,
    longitude: -0.128,
    triggerType: "fallDetection",
    address: "Rural corridor — weak signal area",
  },
  urbanCrime: {
    victimName: "James Chen",
    latitude: 51.515,
    longitude: -0.092,
    triggerType: "panicMovement",
    address: "East London high-risk zone",
  },
};

let running = false;

export function getDemoStatus() {
  return { running, scenarios: Object.keys(SCENARIOS) };
}

/**
 * Full hackathon demo: mobile SOS → command center → AI risk alert → dispatch.
 */
export async function runHackathonDemo(scenarioKey = "ruralSos") {
  if (running) return { ok: false, message: "Demo already running." };
  running = true;

  const scenario = SCENARIOS[scenarioKey] || SCENARIOS.ruralSos;
  const eventId = `demo_${Date.now()}`;

  const incident = {
    eventId,
    uid: "demo-user",
    victimName: scenario.victimName,
    latitude: scenario.latitude,
    longitude: scenario.longitude,
    address: scenario.address,
    triggerType: scenario.triggerType,
    silent: false,
    status: "active",
    incidentStatus: "incoming",
    priority: "critical",
  };

  notifySosTriggered(incident);

  setTimeout(() => {
    broadcastSafetyAlert({
      level: "warning",
      title: "Danger zone proximity",
      message: "Victim path intersects predicted crime hotspot — score 78/100",
      eventId,
    });
  }, 2800);

  setTimeout(() => {
    broadcast("sos:location", {
      eventId,
      latitude: scenario.latitude + 0.001,
      longitude: scenario.longitude + 0.0008,
      speed: 0.2,
      heading: 90,
    });
  }, 4000);

  setTimeout(() => {
    broadcast("responder:assigned", {
      eventId,
      responder: { name: "Metro Ambulance Unit 7", type: "ambulance" },
      etaMinutes: 6,
      distanceKm: 2.1,
    });
    broadcast("incident:status", { eventId, incidentStatus: "dispatched" });
  }, 5500);

  setTimeout(() => {
    broadcast("notification", {
      level: "info",
      title: "Incident contained",
      message: "Responder on scene — victim stable. Demo complete.",
      eventId,
    });
    running = false;
  }, 9000);

  return {
    ok: true,
    eventId,
    scenario: scenarioKey,
    message: "Hackathon demo sequence started (~9s).",
    steps: [
      "SOS triggered (WebSocket)",
      "Command center alert",
      "AI danger zone warning",
      "Live GPS update",
      "Responder dispatched",
    ],
  };
}
