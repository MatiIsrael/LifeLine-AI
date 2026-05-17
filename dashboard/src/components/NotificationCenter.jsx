export default function NotificationCenter({ notifications, safetyAlerts }) {
  return (
    <div className="panel notif-panel">
      <div className="panel-head">
        <h2>Real-time notifications</h2>
        <span style={{ fontFamily: "var(--mono)", fontSize: "0.7rem", color: "var(--muted)" }}>
          {notifications.length}
        </span>
      </div>
      <div className="panel-body">
        {safetyAlerts && (
          <div className="notif-item warning">
            <strong>Route safety</strong>
            <div>{safetyAlerts}</div>
          </div>
        )}
        {notifications.length === 0 && !safetyAlerts ? (
          <p style={{ padding: 16, color: "var(--muted)", fontSize: "0.85rem", textAlign: "center" }}>
            Listening for alerts…
          </p>
        ) : (
          notifications.map((n) => (
            <div key={n.id} className={`notif-item ${n.level || "info"}`}>
              <strong>{n.title || "Alert"}</strong>
              <div>{n.message}</div>
              <small>{new Date(n.at).toLocaleTimeString()}</small>
            </div>
          ))
        )}
      </div>
    </div>
  );
}
