import { Router } from "express";
import {
  attachEmergencyAudio,
  triggerSos,
  updateSosLocation,
  resolveSos,
} from "../services/sosService.js";

const router = Router();

router.post("/trigger", async (req, res) => {
  try {
    const uid = req.user.uid;
    const {
      latitude,
      longitude,
      address,
      silent = false,
      triggerType = "manual",
      recordAudio = false,
      audioPath = null,
    } = req.body;

    const result = await triggerSos({
      uid,
      latitude,
      longitude,
      address,
      silent,
      triggerType,
      recordAudio,
      audioPath,
    });

    return res.json({
      message: "SOS triggered successfully.",
      ...result,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    return res.status(400).json({ message: error.message });
  }
});

router.post("/:eventId/audio", async (req, res) => {
  try {
    const uid = req.user.uid;
    const { eventId } = req.params;
    const { audioUrl } = req.body;

    await attachEmergencyAudio({ uid, eventId, audioUrl });
    return res.json({ message: "Audio attached to emergency." });
  } catch (error) {
    return res.status(400).json({ message: error.message });
  }
});

router.post("/:eventId/location", async (req, res) => {
  try {
    const uid = req.user.uid;
    const { eventId } = req.params;
    const { latitude, longitude, speed, heading } = req.body;

    await updateSosLocation({
      uid,
      eventId,
      latitude,
      longitude,
      speed,
      heading,
    });

    return res.json({ message: "Location updated." });
  } catch (error) {
    return res.status(400).json({ message: error.message });
  }
});

router.post("/:eventId/resolve", async (req, res) => {
  try {
    const uid = req.user.uid;
    const { eventId } = req.params;
    const { notes } = req.body;

    await resolveSos({ uid, eventId, notes });
    return res.json({ message: "Emergency resolved." });
  } catch (error) {
    return res.status(400).json({ message: error.message });
  }
});

export default router;
