import { Router } from "express";
import {
  analyzeRouteSafety,
  buildHeatmap,
  getPredictiveAlerts,
  predictHotspots,
  scorePoint,
} from "../services/dangerZoneEngine.js";

/** Read-only safety API for demos and web preview (no auth). */
const router = Router();

router.get("/risk", async (req, res) => {
  try {
    const lat = parseFloat(req.query.lat);
    const lng = parseFloat(req.query.lng);
    const result = await scorePoint(lat, lng);
    return res.json({ risk: result });
  } catch (error) {
    return res.status(400).json({ message: error.message });
  }
});

router.get("/heatmap", async (req, res) => {
  try {
    const lat = parseFloat(req.query.lat ?? "51.5074");
    const lng = parseFloat(req.query.lng ?? "-0.1278");
    const radiusKm = parseFloat(req.query.radiusKm || "2.5");
    const heatmap = await buildHeatmap({ latitude: lat, longitude: lng, radiusKm });
    return res.json({ heatmap });
  } catch (error) {
    return res.status(400).json({ message: error.message });
  }
});

router.get("/hotspots", async (req, res) => {
  try {
    const lat = parseFloat(req.query.lat ?? "51.5074");
    const lng = parseFloat(req.query.lng ?? "-0.1278");
    const hotspots = await predictHotspots({ latitude: lat, longitude: lng });
    return res.json({ hotspots });
  } catch (error) {
    return res.status(400).json({ message: error.message });
  }
});

router.get("/alerts", async (req, res) => {
  try {
    const lat = parseFloat(req.query.lat ?? "51.5074");
    const lng = parseFloat(req.query.lng ?? "-0.1278");
    const alerts = await getPredictiveAlerts({ latitude: lat, longitude: lng });
    return res.json(alerts);
  } catch (error) {
    return res.status(400).json({ message: error.message });
  }
});

router.post("/route-safety", async (req, res) => {
  try {
    const { origin, destination } = req.body;
    const analysis = await analyzeRouteSafety({ origin, destination });
    return res.json({ analysis });
  } catch (error) {
    return res.status(400).json({ message: error.message });
  }
});

export default router;
