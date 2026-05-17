import { Router } from "express";
import { getDemoStatus, runHackathonDemo } from "../services/demoSimulationService.js";
import { verifyDashboardAccess } from "../middleware/dashboardAuth.js";

const router = Router();

router.use(verifyDashboardAccess);

router.get("/status", (_req, res) => {
  res.json(getDemoStatus());
});

router.post("/hackathon-run", async (req, res) => {
  try {
    const { scenario } = req.body;
    const result = await runHackathonDemo(scenario || "ruralSos");
    return res.json(result);
  } catch (error) {
    return res.status(400).json({ message: error.message });
  }
});

export default router;
