import { useCallback, useEffect, useState } from "react";
import { api } from "../api";

const DEMO_HEATMAP = {
  cells: [
    { latitude: 51.515, longitude: -0.14, riskScore: 78, riskLevel: "critical", weight: 0.78 },
    { latitude: 51.512, longitude: -0.135, riskScore: 65, riskLevel: "high", weight: 0.65 },
    { latitude: 51.508, longitude: -0.125, riskScore: 52, riskLevel: "medium", weight: 0.52 },
    { latitude: 51.505, longitude: -0.118, riskScore: 88, riskLevel: "critical", weight: 0.88 },
    { latitude: 51.502, longitude: -0.11, riskScore: 45, riskLevel: "medium", weight: 0.45 },
    { latitude: 51.51, longitude: -0.105, riskScore: 71, riskLevel: "high", weight: 0.71 },
  ],
};

const DEMO_ANALYTICS = {
  dataSource: "demo",
  incidentCount: 18,
  reportCount: 3,
  crimeIncidents: 10,
  accidentIncidents: 8,
  cityCenterRisk: 62,
  highRiskCells: 6,
  modelVersion: "lifeline-predict-v1",
};

export function useSafety(center = { lat: 51.5074, lng: -0.1278 }) {
  const [heatmap, setHeatmap] = useState(null);
  const [hotspots, setHotspots] = useState(null);
  const [analytics, setAnalytics] = useState(null);
  const [routeAnalysis, setRouteAnalysis] = useState(null);
  const [loading, setLoading] = useState(true);
  const [demoMode, setDemoMode] = useState(false);
  const [showDangerLayer, setShowDangerLayer] = useState(true);

  const refresh = useCallback(async () => {
    setLoading(true);
    try {
      const [hm, hs, an] = await Promise.all([
        api.safetyHeatmap(center.lat, center.lng),
        api.safetyHotspots(center.lat, center.lng),
        api.safetyAnalytics(),
      ]);
      setHeatmap(hm.heatmap);
      setHotspots(hs.hotspots);
      setAnalytics(an.analytics);
      setDemoMode(false);
    } catch {
      setDemoMode(true);
      setHeatmap(DEMO_HEATMAP);
      setHotspots({
        crimeHotspots: DEMO_HEATMAP.cells.filter((c) => c.riskScore >= 60).map((c) => ({
          ...c,
          type: "crime_hotspot",
          label: "Crime hotspot",
        })),
        accidentZones: DEMO_HEATMAP.cells.filter((c) => c.riskScore >= 50).slice(0, 3).map((c) => ({
          ...c,
          type: "accident_prone",
          label: "Accident zone",
        })),
        unsafeAreas: DEMO_HEATMAP.cells.filter((c) => c.riskScore >= 55),
      });
      setAnalytics(DEMO_ANALYTICS);
    } finally {
      setLoading(false);
    }
  }, [center.lat, center.lng]);

  useEffect(() => {
    refresh();
  }, [refresh]);

  const analyzeRoute = async (origin, destination) => {
    try {
      const res = await api.safetyRoute(origin, destination);
      setRouteAnalysis(res.analysis);
      return res.analysis;
    } catch {
      const demo = {
        directRoute: { averageRisk: 58, maxRisk: 78, highRiskCount: 2 },
        recommendation: "High risk segment — use suggested detour via main road.",
        safetyRating: "high",
        saferAlternative: { averageRisk: 38, message: "Detour reduces risk exposure by ~20 points." },
      };
      setRouteAnalysis(demo);
      return demo;
    }
  };

  return {
    heatmap,
    hotspots,
    analytics,
    routeAnalysis,
    loading,
    demoMode,
    showDangerLayer,
    setShowDangerLayer,
    refresh,
    analyzeRoute,
  };
}
