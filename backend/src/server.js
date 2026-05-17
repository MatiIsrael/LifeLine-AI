import "dotenv/config";
import http from "http";
import cors from "cors";
import express from "express";
import helmet from "helmet";
import morgan from "morgan";

import { verifyFirebaseToken } from "./middleware/auth.js";
import { verifyDashboardAccess } from "./middleware/dashboardAuth.js";
import { initRealtimeHub } from "./realtime/realtimeHub.js";
import authRoutes from "./routes/authRoutes.js";
import profileRoutes from "./routes/profileRoutes.js";
import sosRoutes from "./routes/sosRoutes.js";
import historyRoutes from "./routes/historyRoutes.js";
import deviceRoutes from "./routes/deviceRoutes.js";
import syncRoutes from "./routes/syncRoutes.js";
import dashboardRoutes from "./routes/dashboardRoutes.js";
import safetyRoutes from "./routes/safetyRoutes.js";
import publicSafetyRoutes from "./routes/publicSafetyRoutes.js";
import demoRoutes from "./routes/demoRoutes.js";

const app = express();
const port = process.env.PORT || 8080;

app.use(helmet({ crossOriginResourcePolicy: { policy: "cross-origin" } }));
app.use(cors());
app.use(express.json());
app.use(morgan("dev"));

app.get("/health", (_req, res) => {
  res.json({ status: "ok", service: "lifeline-ai-backend" });
});

app.use("/api/dashboard", verifyDashboardAccess, dashboardRoutes);
app.use("/api/demo", demoRoutes);
app.use("/api/public/safety", publicSafetyRoutes);

app.use("/api", verifyFirebaseToken);
app.use("/api/safety", safetyRoutes);
app.use("/api/auth", authRoutes);
app.use("/api/profile", profileRoutes);
app.use("/api/sos", sosRoutes);
app.use("/api/sync", syncRoutes);
app.use("/api/history", historyRoutes);
app.use("/api", deviceRoutes);

app.use((err, _req, res, _next) => {
  return res.status(500).json({ message: err.message || "Unexpected server error." });
});

const server = http.createServer(app);
initRealtimeHub(server);

server.listen(port, () => {
  console.log(`Lifeline API listening on port ${port}`);
  console.log(`Dashboard WebSocket: ws://localhost:${port}/ws`);
});
