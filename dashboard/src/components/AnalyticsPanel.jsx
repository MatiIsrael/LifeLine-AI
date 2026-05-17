import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer } from "recharts";

export default function AnalyticsPanel({ analytics, safetyMode }) {
  const buckets = analytics?.hourBuckets || [];
  const byStatus = analytics?.byIncidentStatus || {};

  if (safetyMode) {
    return (
      <div className="panel analytics-panel">
        <div className="panel-head">
          <h2>Prediction model</h2>
        </div>
        <div className="panel-body" style={{ padding: 14, fontSize: "0.85rem", color: "var(--muted)" }}>
          <p><strong style={{ color: "var(--text)" }}>Data sources</strong></p>
          <ul style={{ margin: "8px 0 16px", paddingLeft: 18 }}>
            <li>Historical crime & accident incidents</li>
            <li>User safety reports</li>
            <li>GPS movement patterns</li>
            <li>Time-of-day risk multipliers</li>
          </ul>
          <p>Model: <code>{analytics?.modelVersion ?? "lifeline-predict-v1"}</code></p>
          <p>Reports: {analytics?.reportCount ?? 0} · Incidents: {analytics?.incidentCount ?? 0}</p>
        </div>
      </div>
    );
  }

  return (
    <div className="panel analytics-panel">
      <div className="panel-head">
        <h2>Emergency analytics</h2>
        <span style={{ fontFamily: "var(--mono)", fontSize: "0.7rem", color: "var(--muted)" }}>
          {analytics?.total ?? 0} total
        </span>
      </div>
      <div className="panel-body">
        <div style={{ display: "flex", gap: 12, marginBottom: 12, flexWrap: "wrap" }}>
          {Object.entries(byStatus).map(([k, v]) => (
            <div key={k} style={{ fontSize: "0.72rem" }}>
              <span style={{ color: "var(--muted)" }}>{k.replace("_", " ")}</span>
              <strong style={{ display: "block", fontFamily: "var(--mono)", color: "#93c5fd" }}>{v}</strong>
            </div>
          ))}
        </div>
        <div className="chart-wrap">
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={buckets}>
              <XAxis dataKey="hour" tick={{ fill: "#7d8aa0", fontSize: 10 }} />
              <YAxis tick={{ fill: "#7d8aa0", fontSize: 10 }} />
              <Tooltip
                contentStyle={{ background: "#121a26", border: "1px solid #243044", borderRadius: 8 }}
                labelStyle={{ color: "#7d8aa0" }}
              />
              <Bar dataKey="count" fill="#3b82f6" radius={[4, 4, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>
    </div>
  );
}
