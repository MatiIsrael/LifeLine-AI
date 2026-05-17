import {
  bboxFromCenter,
  cellId,
  cellCenter,
  haversineKm,
  riskColor,
  riskLevel,
  sampleRoute,
} from "./geospatialService.js";
import { getSafetyDataset } from "./safetyDataService.js";
import { broadcast } from "../realtime/realtimeHub.js";

const RESOLUTION = 0.004;

/** Time-based risk multiplier (smart-city temporal model). */
function timeMultiplier(date = new Date()) {
  const hour = date.getHours();
  const day = date.getDay();
  let m = 1;
  if (hour >= 22 || hour < 5) m *= 1.35;
  if (hour >= 18 && hour < 22) m *= 1.15;
  if (day === 5 || day === 6) m *= 1.1;
  return m;
}

function decayWeight(hoursAgo) {
  if (hoursAgo <= 24) return 1;
  if (hoursAgo <= 72) return 0.7;
  if (hoursAgo <= 168) return 0.45;
  return 0.25;
}

function gaussianInfluence(distanceKm, radiusKm = 0.4) {
  if (distanceKm > radiusKm * 2) return 0;
  return Math.exp(-(distanceKm * distanceKm) / (2 * radiusKm * radiusKm));
}

/**
 * AI-style composite risk score for a coordinate.
 * Sources: historical incidents, user reports, GPS patterns, time analysis.
 */
export async function scorePoint(latitude, longitude, at = new Date()) {
  const dataset = await getSafetyDataset();
  let crime = 0;
  let accident = 0;
  let reports = 0;
  let gps = 0;

  for (const inc of dataset.incidents) {
    const dist = haversineKm(latitude, longitude, inc.latitude, inc.longitude);
    const hoursAgo = inc.recordedAt
      ? (at - new Date(inc.recordedAt)) / 3600000
      : 48;
    const w = gaussianInfluence(dist) * decayWeight(hoursAgo) * (inc.severity || 0.5);
    if (inc.type === "crime") crime += w * 28;
    else if (inc.type === "accident") accident += w * 32;
  }

  for (const rep of dataset.reports) {
    const dist = haversineKm(latitude, longitude, rep.latitude, rep.longitude);
    reports += gaussianInfluence(dist, 0.35) * (rep.weight || 1) * 22;
  }

  for (const pat of dataset.gpsPatterns) {
    const dist = haversineKm(latitude, longitude, pat.latitude, pat.longitude);
    gps += gaussianInfluence(dist, 0.3) * (pat.density || 0.5) * 18;
  }

  const raw = (crime + accident + reports + gps) * timeMultiplier(at);
  const score = Math.min(100, Math.round(raw));
  const level = riskLevel(score);

  return {
    latitude,
    longitude,
    riskScore: score,
    riskLevel: level,
    riskColor: riskColor(score),
    factors: {
      crime: Math.round(crime),
      accident: Math.round(accident),
      userReports: Math.round(reports),
      gpsPatterns: Math.round(gps),
      timeFactor: Number(timeMultiplier(at).toFixed(2)),
    },
    predictedAt: at.toISOString(),
  };
}

function accumulateCellScores(dataset, at) {
  const cells = new Map();
  const add = (lat, lng, amount) => {
    const id = cellId(lat, lng, RESOLUTION);
    const c = cellCenter(id, RESOLUTION);
    const prev = cells.get(id) || { ...c, raw: 0 };
    prev.raw += amount;
    cells.set(id, prev);
  };

  for (const inc of dataset.incidents) {
    const hoursAgo = inc.recordedAt ? (at - new Date(inc.recordedAt)) / 3600000 : 48;
    const base = (inc.type === "crime" ? 28 : 32) * decayWeight(hoursAgo) * (inc.severity || 0.5);
    add(inc.latitude, inc.longitude, base);
    for (let d = -1; d <= 1; d++) {
      for (let e = -1; e <= 1; e++) {
        if (d === 0 && e === 0) continue;
        add(inc.latitude + d * RESOLUTION * 0.8, inc.longitude + e * RESOLUTION * 0.8, base * 0.4);
      }
    }
  }
  for (const rep of dataset.reports) {
    add(rep.latitude, rep.longitude, 22 * (rep.weight || 1));
  }
  for (const pat of dataset.gpsPatterns) {
    add(pat.latitude, pat.longitude, 18 * (pat.density || 0.5));
  }

  const tm = timeMultiplier(at);
  return [...cells.values()].map((c) => {
    const riskScore = Math.min(100, Math.round(c.raw * tm));
    return {
      cellId: cellId(c.latitude, c.longitude, RESOLUTION),
      latitude: c.latitude,
      longitude: c.longitude,
      weight: riskScore / 100,
      riskScore,
      riskLevel: riskLevel(riskScore),
    };
  });
}

/** Build heatmap grid cells for map overlay. */
export async function buildHeatmap({ latitude, longitude, radiusKm = 2.5 }) {
  const dataset = await getSafetyDataset();
  const at = new Date();
  const allCells = accumulateCellScores(dataset, at);
  const points = allCells.filter(
    (c) => haversineKm(latitude, longitude, c.latitude, c.longitude) <= radiusKm && c.riskScore >= 12,
  );

  return {
    center: { latitude, longitude },
    radiusKm,
    cellCount: points.length,
    cells: points,
    generatedAt: at.toISOString(),
  };
}

/** Crime hotspots + accident-prone segments. */
export async function predictHotspots({ latitude, longitude, radiusKm = 3 }) {
  const heatmap = await buildHeatmap({ latitude, longitude, radiusKm });
  const crime = heatmap.cells
    .filter((c) => c.riskScore >= 40)
    .sort((a, b) => b.riskScore - a.riskScore)
    .slice(0, 8)
    .map((c) => ({ ...c, type: "crime_hotspot", label: "Predicted crime hotspot" }));

  const accidents = heatmap.cells
    .filter((c) => c.riskScore >= 35)
    .sort((a, b) => b.riskScore - a.riskScore)
    .slice(0, 6)
    .map((c) => ({ ...c, type: "accident_prone", label: "Accident-prone corridor" }));

  return {
    crimeHotspots: crime,
    accidentZones: accidents,
    unsafeAreas: heatmap.cells.filter((c) => c.riskScore >= 55),
  };
}

/** Smart route safety — compare direct path vs offset safer path. */
export async function analyzeRouteSafety({ origin, destination }) {
  const directSamples = sampleRoute(origin, destination, 14);
  const scored = [];
  for (const p of directSamples) {
    scored.push(await scorePoint(p.latitude, p.longitude));
  }

  const maxRisk = Math.max(...scored.map((s) => s.riskScore));
  const avgRisk = Math.round(scored.reduce((a, s) => a + s.riskScore, 0) / scored.length);
  const highRiskSegments = scored.filter((s) => s.riskScore >= 55);

  let recommendation = "Route appears within normal urban risk parameters.";
  let saferAlt = null;

  if (avgRisk >= 50 || maxRisk >= 70) {
    const mid = scored[Math.floor(scored.length / 2)];
    const offsetLat = mid.latitude + 0.004;
    const offsetLng = mid.longitude - 0.003;
    const altSamples = sampleRoute(
      { lat: origin.lat + 0.003, lng: origin.lng - 0.002 },
      { lat: destination.lat + 0.003, lng: destination.lng - 0.002 },
      14,
    );
    let altScores = [];
    for (const p of altSamples) {
      altScores.push(await scorePoint(p.latitude, p.longitude));
    }
    const altAvg = Math.round(altScores.reduce((a, s) => a + s.riskScore, 0) / altScores.length);
    if (altAvg < avgRisk - 8) {
      saferAlt = {
        waypoints: altSamples,
        averageRisk: altAvg,
        message: "Suggested detour reduces exposure to predicted hotspots.",
      };
      recommendation = "Take suggested safer route — avoids predicted crime/accident clusters.";
    } else {
      recommendation = "High risk segment detected — travel in groups, share live location, avoid 22:00–05:00.";
    }
  }

  return {
    directRoute: {
      samples: scored,
      averageRisk: avgRisk,
      maxRisk,
      highRiskCount: highRiskSegments.length,
    },
    recommendation,
    saferAlternative: saferAlt,
    safetyRating: riskLevel(avgRisk),
  };
}

/** Predictive alerts for user approaching danger zones. */
export async function getPredictiveAlerts({ latitude, longitude, heading, speedKmh = 0 }) {
  const point = await scorePoint(latitude, longitude);
  const hotspots = await predictHotspots({ latitude, longitude, radiusKm: 1.2 });
  const alerts = [];

  if (point.riskScore >= 55) {
    alerts.push({
      level: point.riskLevel,
      title: "High-risk area",
      message: `You are in a predicted ${point.riskLevel} risk zone (score ${point.riskScore}/100). Enable live sharing.`,
      riskScore: point.riskScore,
    });
  }

  if (point.factors.timeFactor >= 1.3 && point.riskScore >= 35) {
    alerts.push({
      level: "warning",
      title: "Night-time risk elevated",
      message: "Historical patterns show increased incidents in this area during current hours.",
      riskScore: point.riskScore,
    });
  }

  for (const zone of hotspots.unsafeAreas.slice(0, 2)) {
    const dist = haversineKm(latitude, longitude, zone.latitude, zone.longitude);
    if (dist < 0.35 && dist > 0.05) {
      alerts.push({
        level: "critical",
        title: "Approaching danger zone",
        message: `Predicted unsafe area ${Math.round(dist * 1000)}m ahead. Consider alternate path.`,
        riskScore: zone.riskScore,
      });
    }
  }

  if (speedKmh > 60 && point.factors.accident >= 25) {
    alerts.push({
      level: "warning",
      title: "Accident-prone road",
      message: "AI model flags this corridor for elevated collision history. Reduce speed.",
      riskScore: point.riskScore,
    });
  }

  return {
    current: point,
    alerts,
    nearbyHotspots: hotspots.crimeHotspots.slice(0, 3),
  };
}

export async function getSafetyAnalytics() {
  const dataset = await getSafetyDataset();
  const crimeCount = dataset.incidents.filter((i) => i.type === "crime").length;
  const accidentCount = dataset.incidents.filter((i) => i.type === "accident").length;

  const center = await scorePoint(51.5074, -0.1278);
  const heatmap = await buildHeatmap({ latitude: 51.5074, longitude: -0.1278, radiusKm: 2 });

  return {
    dataSource: dataset.source,
    incidentCount: dataset.incidents.length,
    reportCount: dataset.reports.length,
    gpsPatternCount: dataset.gpsPatterns.length,
    crimeIncidents: crimeCount,
    accidentIncidents: accidentCount,
    cityCenterRisk: center.riskScore,
    highRiskCells: heatmap.cells.filter((c) => c.riskScore >= 55).length,
    modelVersion: "lifeline-predict-v1",
    lastRun: new Date().toISOString(),
  };
}

export function broadcastSafetyAlert(alert) {
  broadcast("safety:alert", alert);
  broadcast("notification", {
    level: alert.level || "warning",
    title: alert.title || "Safety prediction",
    message: alert.message,
  });
}
