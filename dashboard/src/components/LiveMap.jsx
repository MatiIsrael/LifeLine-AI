import { useMemo } from "react";
import { Circle, GoogleMap, Marker, Polyline, useJsApiLoader } from "@react-google-maps/api";

const MAP_STYLE = [
  { elementType: "geometry", stylers: [{ color: "#0c1018" }] },
  { elementType: "labels.text.fill", stylers: [{ color: "#7d8aa0" }] },
  { elementType: "labels.text.stroke", stylers: [{ color: "#06080d" }] },
  { featureType: "road", elementType: "geometry", stylers: [{ color: "#1a2436" }] },
  { featureType: "water", elementType: "geometry", stylers: [{ color: "#0a1628" }] },
  { featureType: "poi", stylers: [{ visibility: "off" }] },
];

const TYPE_ICON = {
  ambulance: "🚑",
  police: "🚔",
  hospital: "🏥",
  coordinator: "📡",
};

function cellColor(score) {
  if (score >= 75) return "#ef4444";
  if (score >= 55) return "#f97316";
  if (score >= 35) return "#eab308";
  return "#22c55e";
}

export default function LiveMap({ incidents, responders, selected, route, heatmapCells, showDangerLayer }) {
  const apiKey = import.meta.env.VITE_GOOGLE_MAPS_API_KEY;
  const { isLoaded } = useJsApiLoader({
    googleMapsApiKey: apiKey || "",
    id: "lifeline-command-map",
  });

  const center = useMemo(() => {
    if (selected?.latitude) return { lat: selected.latitude, lng: selected.longitude };
    if (incidents[0]?.latitude) return { lat: incidents[0].latitude, lng: incidents[0].longitude };
    return { lat: 51.5074, lng: -0.1278 };
  }, [selected, incidents]);

  const trail = selected?.locationTrail || [];

  if (!apiKey) {
    return (
      <div className="panel map-panel">
        <div className="panel-head">
          <h2>Live emergency map</h2>
        </div>
        <div className="map-container map-fallback">
          <p>Set <code>VITE_GOOGLE_MAPS_API_KEY</code> in dashboard/.env</p>
          <p style={{ fontSize: "0.8rem" }}>
            {incidents.length} incident(s) · {heatmapCells?.length ?? 0} risk zone(s)
          </p>
          {showDangerLayer && heatmapCells?.length > 0 && (
            <div style={{ marginTop: 12, fontSize: "0.75rem", color: "var(--muted)" }}>
              {heatmapCells.slice(0, 5).map((c) => (
                <div key={c.cellId}>Zone score {c.riskScore} — {c.riskLevel}</div>
              ))}
            </div>
          )}
          {selected && (
            <p style={{ fontFamily: "var(--mono)", fontSize: "0.75rem" }}>
              Selected: {selected.victimName} @ {selected.latitude?.toFixed(4)}, {selected.longitude?.toFixed(4)}
            </p>
          )}
        </div>
      </div>
    );
  }

  return (
    <div className="panel map-panel">
      <div className="panel-head">
        <h2>Live danger & emergency map</h2>
        <span style={{ fontSize: "0.7rem", color: showDangerLayer ? "#f97316" : "var(--muted)" }}>
          {showDangerLayer ? "Heatmap ON" : "Heatmap OFF"}
        </span>
      </div>
      <div className="map-container">
        {!isLoaded ? (
          <div className="map-fallback">Loading map…</div>
        ) : (
          <GoogleMap
            mapContainerStyle={{ width: "100%", height: "100%", minHeight: "420px" }}
            center={center}
            zoom={13}
            options={{
              styles: MAP_STYLE,
              disableDefaultUI: false,
              zoomControl: true,
              streetViewControl: false,
              mapTypeControl: false,
            }}
          >
            {showDangerLayer &&
              (heatmapCells ?? []).map((cell) => (
                <Circle
                  key={cell.cellId}
                  center={{ lat: cell.latitude, lng: cell.longitude }}
                  radius={120 + cell.riskScore * 2}
                  options={{
                    fillColor: cellColor(cell.riskScore),
                    fillOpacity: 0.28 + cell.weight * 0.2,
                    strokeColor: cellColor(cell.riskScore),
                    strokeOpacity: 0.5,
                    strokeWeight: 1,
                    clickable: false,
                  }}
                />
              ))}
            {incidents.map((inc) => (
              <Marker
                key={inc.eventId}
                position={{ lat: inc.latitude, lng: inc.longitude }}
                label={{
                  text: "SOS",
                  color: inc.eventId === selected?.eventId ? "#fff" : "#ef4444",
                  fontWeight: "bold",
                }}
                icon={
                  inc.eventId === selected?.eventId
                    ? undefined
                    : "http://maps.google.com/mapfiles/ms/icons/red-dot.png"
                }
              />
            ))}
            {responders.map((r) => (
              <Marker
                key={r.id}
                position={{ lat: r.latitude, lng: r.longitude }}
                title={r.name}
                label={{ text: TYPE_ICON[r.type] || "•", fontSize: "14px" }}
              />
            ))}
            {trail.length > 1 && (
              <Polyline
                path={trail.map((p) => ({ lat: p.latitude, lng: p.longitude }))}
                options={{ strokeColor: "#3b82f6", strokeWeight: 4, strokeOpacity: 0.8 }}
              />
            )}
            {route?.origin && route?.destination && (
              <Polyline
                path={[
                  { lat: route.origin.lat, lng: route.origin.lng },
                  { lat: route.destination.lat, lng: route.destination.lng },
                ]}
                options={{ strokeColor: "#22c55e", strokeWeight: 3, strokeOpacity: 0.9, geodesic: true }}
              />
            )}
          </GoogleMap>
        )}
      </div>
    </div>
  );
}
