import { useState } from "react";
import { useWebSocket } from "../hooks/useWebSocket";
import { useDashboard } from "../hooks/useDashboard";
import { useSafety } from "../hooks/useSafety";
import TopBar from "../components/TopBar";
import SosFeed from "../components/SosFeed";
import LiveMap from "../components/LiveMap";
import IncidentPanel from "../components/IncidentPanel";
import AnalyticsPanel from "../components/AnalyticsPanel";
import RiskAnalyticsPanel from "../components/RiskAnalyticsPanel";
import NotificationCenter from "../components/NotificationCenter";

export default function Dashboard({ onLogout }) {
  const dash = useDashboard();
  const safety = useSafety();
  const { connected } = useWebSocket(dash.handleWsMessage);
  const [routeInfo, setRouteInfo] = useState(null);
  const [viewMode, setViewMode] = useState("command");

  const handleOptimize = async () => {
    const result = await dash.optimizeRoute();
    if (result?.route) setRouteInfo(result);
    else if (result?.recommendedResponder) setRouteInfo(result);
  };

  const handleAssign = async (responderId) => {
    await dash.assignResponder(responderId);
    setRouteInfo(null);
  };

  const handleRouteSafety = () => {
    safety.analyzeRoute(
      { lat: 51.5074, lng: -0.1278 },
      { lat: 51.52, lng: -0.09 },
    );
  };

  return (
    <div className="command-root">
      {(dash.demoMode || safety.demoMode) && (
        <div className="demo-banner">
          Demo mode — sample incidents & AI safety predictions active.
        </div>
      )}
      <TopBar
        analytics={dash.analytics}
        connected={connected}
        demoMode={dash.demoMode}
        onRefresh={() => {
          dash.refresh();
          safety.refresh();
        }}
        onLogout={onLogout}
        onRunDemo={dash.runLiveDemo}
        viewMode={viewMode}
        onViewModeChange={setViewMode}
        safetyEnabled={safety.showDangerLayer}
        onToggleSafety={() => safety.setShowDangerLayer((v) => !v)}
      />
      <main className={`main-grid ${viewMode === "safety" ? "safety-mode" : ""}`}>
        <SosFeed
          incidents={dash.incidents}
          selectedId={dash.selectedId}
          onSelect={dash.setSelectedId}
        />
        <LiveMap
          incidents={dash.incidents}
          responders={dash.responders}
          selected={dash.selected}
          route={routeInfo?.route}
          heatmapCells={safety.heatmap?.cells}
          showDangerLayer={safety.showDangerLayer}
        />
        {viewMode === "safety" ? (
          <RiskAnalyticsPanel
            analytics={safety.analytics}
            hotspots={safety.hotspots}
            demoMode={safety.demoMode}
            onRouteAnalyze={handleRouteSafety}
          />
        ) : (
          <IncidentPanel
            incident={dash.selected}
            responders={dash.responders}
            onStatus={dash.updateStatus}
            onAssign={handleAssign}
            onOptimize={handleOptimize}
            routeInfo={routeInfo}
            routeSafety={safety.routeAnalysis}
          />
        )}
        {viewMode === "safety" ? (
          <AnalyticsPanel analytics={safety.analytics} safetyMode />
        ) : (
          <AnalyticsPanel analytics={dash.analytics} />
        )}
        <NotificationCenter
          notifications={dash.notifications}
          safetyAlerts={safety.routeAnalysis?.recommendation}
        />
      </main>
    </div>
  );
}
