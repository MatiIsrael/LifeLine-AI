export default function TopBar({
  analytics,
  connected,
  demoMode,
  onRefresh,
  onLogout,
  onRunDemo,
  viewMode,
  onViewModeChange,
  safetyEnabled,
  onToggleSafety,
}) {
  return (
    <header className="topbar">
      <div className="topbar-brand">
        <div className="logo">⬡</div>
        <div>
          <div>Lifeline Command</div>
          <div style={{ fontSize: "0.7rem", color: "var(--muted)", fontWeight: 400 }}>
            Smart-city emergency infrastructure
          </div>
        </div>
      </div>
      <div className="topbar-meta">
        <div className="stat-pill critical">
          <span className={`live-dot ${connected ? "" : "off"}`} />
          Active <strong>{analytics?.active ?? "—"}</strong>
        </div>
        <div className="stat-pill">
          Risk AI <strong>{safetyEnabled ? "ON" : "OFF"}</strong>
        </div>
        <div className="stat-pill">
          WS <strong>{connected ? "LIVE" : "OFF"}</strong>
        </div>
        {demoMode && <div className="stat-pill" style={{ color: "#fcd34d" }}>DEMO</div>}
      </div>
      <div className="topbar-actions">
        <button type="button" className="btn btn-demo" onClick={onRunDemo}>
          ▶ Launch live demo
        </button>
        <button
          type="button"
          className={`btn ${viewMode === "safety" ? "btn-primary" : ""}`}
          onClick={() => onViewModeChange?.(viewMode === "safety" ? "command" : "safety")}
        >
          {viewMode === "safety" ? "Command view" : "Risk AI view"}
        </button>
        <button type="button" className="btn" onClick={onToggleSafety}>
          Heatmap {safetyEnabled ? "ON" : "OFF"}
        </button>
        <button type="button" className="btn" onClick={onRefresh}>
          Refresh
        </button>
        <button type="button" className="btn btn-danger" onClick={onLogout}>
          Sign out
        </button>
      </div>
    </header>
  );
}
