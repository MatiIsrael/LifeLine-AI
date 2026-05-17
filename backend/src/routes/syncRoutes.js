import { Router } from "express";
import { syncQueuedSos } from "../services/syncService.js";

const router = Router();

router.post("/sos", async (req, res) => {
  try {
    const uid = req.user.uid;
    const { localId, version, payload, serverEventId } = req.body;

    const result = await syncQueuedSos({
      uid,
      localId,
      version,
      payload,
      serverEventId,
    });

    return res.json({
      message: "SOS sync processed.",
      ...result,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    return res.status(400).json({ message: error.message });
  }
});

export default router;
