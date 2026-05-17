const STATUS_CLASS = {
  incoming: "badge-incoming",
  dispatched: "badge-dispatched",
  en_route: "badge-en_route",
  on_scene: "badge-on_scene",
  resolved: "badge-resolved",
};

export default function StatusBadge({ status, priority }) {
  const cls = STATUS_CLASS[status] || "badge-incoming";
  return (
    <span className={`badge ${cls} ${priority === "critical" ? "badge-critical" : ""}`}>
      {(status || "incoming").replace("_", " ")}
    </span>
  );
}
