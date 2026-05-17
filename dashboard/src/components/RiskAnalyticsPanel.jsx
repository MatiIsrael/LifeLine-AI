export default function RiskAnalyticsPanel({ analytics, hotspots, demoMode, onRouteAnalyze }) {
  if (!analytics) {
    return (
      <div className="panel risk-panel">
        <div className="panel-head"><h2>AI risk analytics</h2></div>
        <div className="panel-body"><p style={{ padding: 16, color: "var(--muted)" }}>Loading…</p></div>
      </div>
    );
  }

  return (
    <div className="panel risk-panel">
      <div className="panel-head">
        <h2>Smart-city risk analytics</h2>
        {demoMode && <span style={{ fontSize: "0.65rem", color: "#fcd34d" }}>DEMO</span>}
      </div>
      <div className="panel-body risk-body">
        <div className="risk-stat-grid">
          <div className="risk-stat">
            <span className="label">City risk index</span>
            <strong className="score">{analytics.cityCenterRisk ?? "—"}</strong>
          </div>
          <div className="risk-stat">
            <span className="label">High-risk zones</span>
            <strong>{analytics.highRiskCells ?? "—"}</strong>
          </div>
          <div className="risk-stat">
            <span className="label">Crime incidents</span>
            <strong>{analytics.crimeIncidents ?? "—"}</strong>
          </div>
          <div className="risk-stat">
            <span className="label">Accident zones</span>
            <strong>{analytics.accidentIncidents ?? "—"}</strong>
          </div>
        </div>

        <p className="risk-section-title">Predicted hotspots</p>
        <ul className="hotspot-list">
          {(hotspots?.crimeHotspots ?? []).slice(0, 3).map((h, i) => (
            <li key={`c-${i}`}>
              <span className="dot crime" />
              <span>Crime — score {h.riskScore}</span>
            </li>
          ))}
          {(hotspots?.accidentZones ?? []).slice(0, 2).map((h, i) => (
            <li key={`a-${i}`}>
              <span className="dot accident" />
              <span>Accident — score {h.riskScore}</span>
            </li>
          ))}
        </ul>

        <button type="button" className="btn btn-primary risk-route-btn" onClick={onRouteAnalyze}>
          Analyze route safety
        </button>
        <p className="risk-model">{analytics.modelVersion} · {analytics.dataSource} data</p>
      </div>
    </div>
  );
}
