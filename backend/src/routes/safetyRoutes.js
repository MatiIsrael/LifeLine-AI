import { Router } from "express";
import {
  analyzeRouteSafety,
  buildHeatmap,
  getPredictiveAlerts,
  getSafetyAnalytics,
  predictHotspots,
  scorePoint,
} from "../services/dangerZoneEngine.js";
import { addUserReport } from "../services/safetyDataService.js";

const router = Router();

router.get("/risk", async (req, res) => {
  try {
    const lat = parseFloat(req.query.lat);
    const lng = parseFloat(req.query.lng);
    if (Number.isNaN(lat) || Number.isNaN(lng)) {
      return res.status(400).json({ message: "lat and lng query params required." });
    }
    const result = await scorePoint(lat, lng);
    return res.json({ risk: result });
  } catch (error) {
    return res.status(400).json({ message: error.message });
  }
});

router.get("/heatmap", async (req, res) => {
  try {
    const lat = parseFloat(req.query.lat);
    const lng = parseFloat(req.query.lng);
    const radiusKm = parseFloat(req.query.radiusKm || "2.5");
    const heatmap = await buildHeatmap({ latitude: lat, longitude: lng, radiusKm });
    return res.json({ heatmap });
  } catch (error) {
    return res.status(400).json({ message: error.message });
  }
});

router.get("/hotspots", async (req, res) => {
  try {
    const lat = parseFloat(req.query.lat);
    const lng = parseFloat(req.query.lng);
    const radiusKm = parseFloat(req.query.radiusKm || "3");
    const hotspots = await predictHotspots({ latitude: lat, longitude: lng, radiusKm });
    return res.json({ hotspots });
  } catch (error) {
    return res.status(400).json({ message: error.message });
  }
});

router.get("/alerts", async (req, res) => {
  try {
    const lat = parseFloat(req.query.lat);
    const lng = parseFloat(req.query.lng);
    const speedKmh = parseFloat(req.query.speedKmh || "0");
    const alerts = await getPredictiveAlerts({
      latitude: lat,
      longitude: lng,
      speedKmh,
    });
    return res.json(alerts);
  } catch (error) {
    return res.status(400).json({ message: error.message });
  }
});

router.post("/route-safety", async (req, res) => {
  try {
    const { origin, destination } = req.body;
    if (!origin?.lat || !destination?.lat) {
      return res.status(400).json({ message: "origin and destination {lat,lng} required." });
    }
    const analysis = await analyzeRouteSafety({ origin, destination });
    return res.json({ analysis });
  } catch (error) {
    return res.status(400).json({ message: error.message });
  }
});

router.post("/reports", async (req, res) => {
  try {
    const { latitude, longitude, category, description } = req.body;
    const uid = req.user?.uid;
    const report = await addUserReport({
      uid,
      latitude,
      longitude,
      category,
      description,
    });
    return res.json({ message: "Safety report submitted.", report });
  } catch (error) {
    return res.status(400).json({ message: error.message });
  }
});

router.get("/analytics", async (req, res) => {
  try {
    const analytics = await getSafetyAnalytics();
    return res.json({ analytics });
  } catch (error) {
    return res.status(400).json({ message: error.message });
  }
});

export default router;
