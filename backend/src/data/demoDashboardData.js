/** In-memory demo data when Firebase is not configured. */
export const DEMO_INCIDENTS = [
  {
    id: "demo-1",
    eventId: "demo-1",
    victimName: "Sarah Mitchell",
    latitude: 51.5074,
    longitude: -0.1278,
    status: "active",
    incidentStatus: "incoming",
    priority: "critical",
    triggerType: "fallDetection",
    triggeredAt: new Date().toISOString(),
    address: "Westminster, London",
  },
  {
    id: "demo-2",
    eventId: "demo-2",
    victimName: "James Okonkwo",
    latitude: 51.515,
    longitude: -0.09,
    status: "active",
    incidentStatus: "dispatched",
    priority: "high",
    triggerType: "manual",
    assignedResponderName: "City Ambulance Unit 7",
    etaMinutes: 6,
    triggeredAt: new Date(Date.now() - 300000).toISOString(),
    address: "Shoreditch, London",
  },
];

export const DEMO_RESPONDERS = [
  { id: "r1", name: "City Ambulance Unit 7", type: "ambulance", status: "dispatched", latitude: 51.51, longitude: -0.12 },
  { id: "r2", name: "Metro Police Patrol 12", type: "police", status: "available", latitude: 51.505, longitude: -0.11 },
  { id: "r3", name: "St. Mary's ER Team", type: "hospital", status: "available", latitude: 51.499, longitude: -0.13 },
];

export const DEMO_ANALYTICS = {
  total: 24,
  active: 2,
  last24hCount: 8,
  avgResponseMinutes: 7.2,
  byIncidentStatus: { incoming: 1, dispatched: 1, en_route: 0, on_scene: 0, resolved: 22 },
  hourBuckets: Array.from({ length: 24 }, (_, h) => ({ hour: h, count: h % 5 })),
};

export function isFirebaseUnavailable(error) {
  const msg = String(error?.message || error || "").toLowerCase();
  return (
    msg.includes("could not load") ||
    msg.includes("credential") ||
    msg.includes("default credentials") ||
    msg.includes("unable to detect") ||
    msg.includes("project id") ||
    msg.includes("firestore") ||
    msg.includes("cannot read properties of null") ||
    msg.includes("reading 'collection'")
  );
}
