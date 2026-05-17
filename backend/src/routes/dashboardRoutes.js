import { Router } from "express";
import { getConnectedClients } from "../realtime/realtimeHub.js";
import {
  assignResponder,
  getAnalytics,
  getIncident,
  listIncidents,
  listResponders,
  optimizeRoute,
  updateIncidentStatus,
  upsertResponder,
} from "../services/dashboardService.js";
import {
  buildHeatmap,
  getSafetyAnalytics,
  predictHotspots,
} from "../services/dangerZoneEngine.js";
import {
  DEMO_ANALYTICS,
  DEMO_INCIDENTS,
  DEMO_RESPONDERS,
  isFirebaseUnavailable,
} from "../data/demoDashboardData.js";
import { firebaseEnabled } from "../config/firebaseAdmin.js";

const router = Router();

router.get("/incidents", async (req, res) => {
  if (!firebaseEnabled) {
    return res.json({ incidents: DEMO_INCIDENTS, demoMode: true });
  }
  try {
    const status = req.query.status || "active";
    const incidents = await listIncidents({ status, limit: 100 });
    return res.json({ incidents, demoMode: false });
  } catch (error) {
    if (isFirebaseUnavailable(error)) {
      return res.json({ incidents: DEMO_INCIDENTS, demoMode: true });
    }
    return res.status(400).json({ message: error.message });
  }
});

router.get("/incidents/:eventId", async (req, res) => {
  try {
    const incident = await getIncident(req.params.eventId);
    return res.json({ incident });
  } catch (error) {
    return res.status(404).json({ message: error.message });
  }
});

router.patch("/incidents/:eventId/status", async (req, res) => {
  try {
    const { incidentStatus, notes } = req.body;
    const result = await updateIncidentStatus({
      eventId: req.params.eventId,
      incidentStatus,
      notes,
      operator: req.operator,
    });
    return res.json(result);
  } catch (error) {
    return res.status(400).json({ message: error.message });
  }
});

router.post("/incidents/:eventId/assign", async (req, res) => {
  try {
    const { responderId } = req.body;
    const result = await assignResponder({
      eventId: req.params.eventId,
      responderId,
      operator: req.operator,
    });
    return res.json(result);
  } catch (error) {
    return res.status(400).json({ message: error.message });
  }
});

router.post("/incidents/:eventId/optimize-route", async (req, res) => {
  try {
    const result = await optimizeRoute({ eventId: req.params.eventId });
    return res.json(result);
  } catch (error) {
    return res.status(400).json({ message: error.message });
  }
});

router.get("/responders", async (req, res) => {
  const availableOnly = req.query.available === "true";
  if (!firebaseEnabled) {
    const list = availableOnly
      ? DEMO_RESPONDERS.filter((r) => r.status === "available")
      : DEMO_RESPONDERS;
    return res.json({ responders: list, demoMode: true });
  }
  try {
    const responders = await listResponders({ availableOnly });
    return res.json({ responders, demoMode: false });
  } catch (error) {
    if (isFirebaseUnavailable(error)) {
      const list = availableOnly
        ? DEMO_RESPONDERS.filter((r) => r.status === "available")
        : DEMO_RESPONDERS;
      return res.json({ responders: list, demoMode: true });
    }
    return res.status(400).json({ message: error.message });
  }
});

router.post("/responders", async (req, res) => {
  try {
    const result = await upsertResponder(req.body);
    return res.json(result);
  } catch (error) {
    return res.status(400).json({ message: error.message });
  }
});

router.get("/analytics", async (req, res) => {
  if (!firebaseEnabled) {
    return res.json({
      analytics: { ...DEMO_ANALYTICS, connectedClients: getConnectedClients() },
      demoMode: true,
    });
  }
  try {
    const analytics = await getAnalytics();
    analytics.connectedClients = getConnectedClients();
    return res.json({ analytics, demoMode: false });
  } catch (error) {
    if (isFirebaseUnavailable(error)) {
      return res.json({
        analytics: { ...DEMO_ANALYTICS, connectedClients: getConnectedClients() },
        demoMode: true,
      });
    }
    return res.status(400).json({ message: error.message });
  }
});

router.get("/health", (_req, res) => {
  res.json({
    status: "ok",
    wsClients: getConnectedClients(),
    service: "lifeline-dashboard-api",
  });
});

router.get("/safety/heatmap", async (req, res) => {
  try {
    const lat = parseFloat(req.query.lat ?? "51.5074");
    const lng = parseFloat(req.query.lng ?? "-0.1278");
    const heatmap = await buildHeatmap({
      latitude: lat,
      longitude: lng,
      radiusKm: parseFloat(req.query.radiusKm || "2.5"),
    });
    return res.json({ heatmap });
  } catch (error) {
    return res.status(400).json({ message: error.message });
  }
});

router.get("/safety/hotspots", async (req, res) => {
  try {
    const lat = parseFloat(req.query.lat ?? "51.5074");
    const lng = parseFloat(req.query.lng ?? "-0.1278");
    const hotspots = await predictHotspots({ latitude: lat, longitude: lng });
    return res.json({ hotspots });
  } catch (error) {
    return res.status(400).json({ message: error.message });
  }
});

router.get("/safety/analytics", async (_req, res) => {
  try {
    const analytics = await getSafetyAnalytics();
    return res.json({ analytics });
  } catch (error) {
    return res.status(400).json({ message: error.message });
  }
});

export default router;
