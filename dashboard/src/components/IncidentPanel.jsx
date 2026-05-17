import StatusBadge from "./StatusBadge";

const STATUSES = ["incoming", "dispatched", "en_route", "on_scene", "resolved"];

export default function IncidentPanel({
  incident,
  responders,
  onStatus,
  onAssign,
  onOptimize,
  routeInfo,
}) {
  if (!incident) {
    return (
      <div className="panel">
        <div className="panel-head"><h2>Incident control</h2></div>
        <div className="panel-body">
          <p style={{ padding: 20, color: "var(--muted)", textAlign: "center" }}>
            Select an incident from the feed
          </p>
        </div>
      </div>
    );
  }

  return (
    <div className="panel">
      <div className="panel-head">
        <h2>Incident control</h2>
        <StatusBadge status={incident.incidentStatus} priority={incident.priority} />
      </div>
      <div className="panel-body">
        <div className="detail-section">
          <h3>Victim</h3>
          <div className="detail-row"><span>Name</span><span>{incident.victimName}</span></div>
          <div className="detail-row"><span>Trigger</span><span>{incident.triggerType}</span></div>
          <div className="detail-row"><span>Priority</span><span>{incident.priority || "high"}</span></div>
          <div className="detail-row">
            <span>Location</span>
            <span style={{ fontFamily: "var(--mono)", fontSize: "0.75rem" }}>
              {incident.latitude?.toFixed(5)}, {incident.longitude?.toFixed(5)}
            </span>
          </div>
          {incident.assignedResponderName && (
            <div className="detail-row">
              <span>Assigned</span>
              <span>{incident.assignedResponderName} · ETA {incident.etaMinutes}m</span>
            </div>
          )}
        </div>

        <div className="detail-section">
          <h3>Status update</h3>
          <div className="status-actions">
            {STATUSES.map((s) => (
              <button key={s} type="button" onClick={() => onStatus(s)}>
                {s.replace("_", " ")}
              </button>
            ))}
          </div>
        </div>

        <div className="detail-section">
          <h3>Route optimization</h3>
          <button type="button" className="btn btn-primary" style={{ width: "100%", marginBottom: 8 }} onClick={onOptimize}>
            Find nearest responder
          </button>
          {routeInfo && (
            <p style={{ fontSize: "0.8rem", color: "var(--muted)" }}>
              Recommended: <strong style={{ color: "#93c5fd" }}>{routeInfo.recommendedResponder?.name}</strong>
              {" "}· {routeInfo.distanceKm} km · ETA {routeInfo.etaMinutes} min
            </p>
          )}
        </div>

        <div className="detail-section">
          <h3>Assign responder</h3>
          {responders
            .filter((r) => r.status === "available" || r.type !== "coordinator")
            .map((r) => (
              <div
                key={r.id}
                className="responder-row"
                onClick={() => onAssign(r.id)}
                onKeyDown={(e) => e.key === "Enter" && onAssign(r.id)}
                role="button"
                tabIndex={0}
              >
                <div className={`responder-icon ${r.type}`}>
                  {r.type === "ambulance" ? "🚑" : r.type === "police" ? "🚔" : r.type === "hospital" ? "🏥" : "📡"}
                </div>
                <div style={{ flex: 1 }}>
                  <div style={{ fontWeight: 600, fontSize: "0.85rem" }}>{r.name}</div>
                  <div style={{ fontSize: "0.72rem", color: "var(--muted)" }}>
                    {r.type} · {r.status}
                  </div>
                </div>
                <button type="button" className="btn btn-primary" style={{ padding: "4px 10px" }}>
                  Dispatch
                </button>
              </div>
            ))}
        </div>
      </div>
    </div>
  );
}
