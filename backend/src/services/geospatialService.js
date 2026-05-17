/** Geospatial utilities for grid-based heatmaps and route sampling. */

const EARTH_RADIUS_KM = 6371;

export function haversineKm(lat1, lon1, lat2, lon2) {
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLon / 2) ** 2;
  return EARTH_RADIUS_KM * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

/** Grid cell id for heatmap aggregation (~500m cells at equator). */
export function cellId(lat, lng, resolution = 0.005) {
  const latCell = Math.floor(lat / resolution);
  const lngCell = Math.floor(lng / resolution);
  return `${latCell}:${lngCell}`;
}

export function cellCenter(cellKey, resolution = 0.005) {
  const [latCell, lngCell] = cellKey.split(":").map(Number);
  return {
    latitude: (latCell + 0.5) * resolution,
    longitude: (lngCell + 0.5) * resolution,
  };
}

export function bboxFromCenter(lat, lng, radiusKm) {
  const latDelta = radiusKm / 111;
  const lngDelta = radiusKm / (111 * Math.cos((lat * Math.PI) / 180));
  return {
    minLat: lat - latDelta,
    maxLat: lat + latDelta,
    minLng: lng - lngDelta,
    maxLng: lng + lngDelta,
  };
}

/** Sample points along a straight route for risk analysis. */
export function sampleRoute(origin, destination, steps = 12) {
  const points = [];
  for (let i = 0; i <= steps; i++) {
    const t = i / steps;
    points.push({
      latitude: origin.lat + (destination.lat - origin.lat) * t,
      longitude: origin.lng + (destination.lng - origin.lng) * t,
    });
  }
  return points;
}

export function riskLevel(score) {
  if (score >= 75) return "critical";
  if (score >= 55) return "high";
  if (score >= 35) return "medium";
  if (score >= 15) return "low";
  return "safe";
}

export function riskColor(score) {
  if (score >= 75) return "#ef4444";
  if (score >= 55) return "#f97316";
  if (score >= 35) return "#eab308";
  if (score >= 15) return "#22c55e";
  return "#3b82f6";
}
