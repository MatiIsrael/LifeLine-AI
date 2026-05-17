const API_BASE = import.meta.env.VITE_API_BASE || "";

export function getDashboardKey() {
  return sessionStorage.getItem("ll_dashboard_key") || import.meta.env.VITE_DASHBOARD_KEY || "lifeline-dashboard-dev";
}

export function setDashboardKey(key) {
  sessionStorage.setItem("ll_dashboard_key", key);
}

async function request(path, options = {}) {
  const headers = {
    "Content-Type": "application/json",
    "X-Dashboard-Key": getDashboardKey(),
    ...options.headers,
  };

  const res = await fetch(`${API_BASE}${path}`, { ...options, headers });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(data.message || `Request failed (${res.status})`);
  return data;
}

export const api = {
  incidents: (status = "active") => request(`/api/dashboard/incidents?status=${status}`),
  incident: (id) => request(`/api/dashboard/incidents/${id}`),
  updateStatus: (id, incidentStatus, notes) =>
    request(`/api/dashboard/incidents/${id}/status`, {
      method: "PATCH",
      body: JSON.stringify({ incidentStatus, notes }),
    }),
  assign: (id, responderId) =>
    request(`/api/dashboard/incidents/${id}/assign`, {
      method: "POST",
      body: JSON.stringify({ responderId }),
    }),
  optimizeRoute: (id) =>
    request(`/api/dashboard/incidents/${id}/optimize-route`, { method: "POST" }),
  responders: (availableOnly = false) =>
    request(`/api/dashboard/responders?available=${availableOnly}`),
  analytics: () => request("/api/dashboard/analytics"),
  safetyHeatmap: (lat, lng, radiusKm = 2.5) =>
    request(`/api/dashboard/safety/heatmap?lat=${lat}&lng=${lng}&radiusKm=${radiusKm}`),
  safetyHotspots: (lat, lng) =>
    request(`/api/dashboard/safety/hotspots?lat=${lat}&lng=${lng}`),
  safetyAnalytics: () => request("/api/dashboard/safety/analytics"),
  runHackathonDemo: (scenario = "ruralSos") =>
    request("/api/demo/hackathon-run", {
      method: "POST",
      body: JSON.stringify({ scenario }),
    }),
  safetyRoute: async (origin, destination) => {
    const res = await fetch(`${API_BASE}/api/public/safety/route-safety`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ origin, destination }),
    });
    const data = await res.json();
    if (!res.ok) throw new Error(data.message || "Route analysis failed");
    return data;
  },
};
