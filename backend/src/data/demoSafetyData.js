/** Demo smart-city safety dataset (London-centred) when Firestore is empty. */

const base = { lat: 51.5074, lng: -0.1278 };

function point(offsetLat, offsetLng, type, severity = 0.7, hoursAgo = 48) {
  return {
    type,
    latitude: base.lat + offsetLat,
    longitude: base.lng + offsetLng,
    severity,
    recordedAt: new Date(Date.now() - hoursAgo * 3600000).toISOString(),
  };
}

export const DEMO_SAFETY_DATA = {
  source: "demo",
  incidents: [
    ...Array.from({ length: 8 }, (_, i) =>
      point(0.008 + i * 0.002, -0.015 + i * 0.001, "crime", 0.65 + i * 0.03, 12 + i * 6),
    ),
    ...Array.from({ length: 6 }, (_, i) =>
      point(-0.012, 0.01 + i * 0.003, "accident", 0.75, 24 + i * 8),
    ),
    point(0.02, 0.018, "crime", 0.9, 6),
    point(-0.018, -0.02, "accident", 0.85, 3),
    point(0.005, 0.022, "crime", 0.55, 72),
  ],
  reports: [
    { latitude: base.lat + 0.01, longitude: base.lng - 0.012, category: "harassment", weight: 1.3 },
    { latitude: base.lat - 0.008, longitude: base.lng + 0.014, category: "poor_lighting", weight: 1.1 },
    { latitude: base.lat + 0.015, longitude: base.lng + 0.008, category: "unsafe_area", weight: 1.4 },
  ],
  gpsPatterns: [
    { latitude: base.lat + 0.009, longitude: base.lng - 0.011, anomaly: "night_loitering", density: 0.8 },
    { latitude: base.lat - 0.01, longitude: base.lng + 0.012, anomaly: "sudden_stop", density: 0.6 },
    { latitude: base.lat + 0.014, longitude: base.lng - 0.006, anomaly: "off_route", density: 0.7 },
  ],
};
