import StatusBadge from "./StatusBadge";

function timeAgo(iso) {
  if (!iso) return "—";
  const s = Math.floor((Date.now() - new Date(iso).getTime()) / 1000);
  if (s < 60) return `${s}s ago`;
  if (s < 3600) return `${Math.floor(s / 60)}m ago`;
  return `${Math.floor(s / 3600)}h ago`;
}

export default function SosFeed({ incidents, selectedId, onSelect }) {
  return (
    <div className="panel">
      <div className="panel-head">
        <h2>Incoming SOS feed</h2>
        <span style={{ fontFamily: "var(--mono)", fontSize: "0.75rem", color: "var(--muted)" }}>
          {incidents.length}
        </span>
      </div>
      <div className="panel-body">
        {incidents.length === 0 ? (
          <p style={{ padding: 20, color: "var(--muted)", textAlign: "center" }}>No active incidents</p>
        ) : (
          incidents.map((inc) => (
            <div
              key={inc.eventId}
              className={`feed-item ${selectedId === inc.eventId ? "selected" : ""}`}
              onClick={() => onSelect(inc.eventId)}
              onKeyDown={(e) => e.key === "Enter" && onSelect(inc.eventId)}
              role="button"
              tabIndex={0}
            >
              <div className="feed-top">
                <span className="feed-name">{inc.victimName || "Unknown"}</span>
                <StatusBadge status={inc.incidentStatus} priority={inc.priority} />
              </div>
              <div className="feed-meta">
                {inc.triggerType} · {inc.address || `${inc.latitude?.toFixed(4)}, ${inc.longitude?.toFixed(4)}`}
              </div>
              <div className="feed-time">{timeAgo(inc.triggeredAt)}</div>
            </div>
          ))
        )}
      </div>
    </div>
  );
}
