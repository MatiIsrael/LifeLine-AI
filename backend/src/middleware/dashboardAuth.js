import { admin } from "../config/firebaseAdmin.js";

/**
 * Dashboard access: Firebase operator token OR shared API key header.
 */
export async function verifyDashboardAccess(req, res, next) {
  const apiKey = req.headers["x-dashboard-key"];
  const expectedKey = process.env.DASHBOARD_API_KEY || "lifeline-dashboard-dev";

  if (apiKey && apiKey === expectedKey) {
    req.operator = { role: "coordinator", source: "api_key" };
    return next();
  }

  try {
    const authHeader = req.headers.authorization || "";
    const token = authHeader.startsWith("Bearer ") ? authHeader.slice(7) : null;
    if (!token) {
      return res.status(401).json({ message: "Dashboard auth required." });
    }

    const decoded = await admin.auth().verifyIdToken(token);
    const role = decoded.dashboardRole || decoded.role || "coordinator";
    req.operator = { uid: decoded.uid, email: decoded.email, role, source: "firebase" };
    return next();
  } catch {
    return res.status(401).json({ message: "Invalid dashboard credentials." });
  }
}
