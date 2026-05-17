import { useCallback, useEffect, useState } from "react";
import { api } from "../api";

const DEMO_INCIDENTS = [
  {
    id: "demo-1",
    eventId: "demo-1",
    victimName: "Sarah Mitchell",
    latitude: 51.5074,
    longitude: -0.1278,
    status: "active",
    incidentStatus: "incoming",
    priority: "critical",
    triggerType: "fallDetection",
    triggeredAt: new Date().toISOString(),
    address: "Westminster, London",
  },
  {
    id: "demo-2",
    eventId: "demo-2",
    victimName: "James Okonkwo",
    latitude: 51.515,
    longitude: -0.09,
    status: "active",
    incidentStatus: "dispatched",
    priority: "high",
    triggerType: "manual",
    assignedResponderName: "City Ambulance Unit 7",
    etaMinutes: 6,
    triggeredAt: new Date(Date.now() - 300000).toISOString(),
    address: "Shoreditch, London",
  },
];

const DEMO_RESPONDERS = [
  { id: "r1", name: "City Ambulance Unit 7", type: "ambulance", status: "dispatched", latitude: 51.51, longitude: -0.12 },
  { id: "r2", name: "Metro Police Patrol 12", type: "police", status: "available", latitude: 51.505, longitude: -0.11 },
  { id: "r3", name: "St. Mary's ER Team", type: "hospital", status: "available", latitude: 51.499, longitude: -0.13 },
];

export function useDashboard() {
  const [incidents, setIncidents] = useState([]);
  const [responders, setResponders] = useState([]);
  const [analytics, setAnalytics] = useState(null);
  const [selectedId, setSelectedId] = useState(null);
  const [notifications, setNotifications] = useState([]);
  const [demoMode, setDemoMode] = useState(false);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const pushNotification = useCallback((n) => {
    const item = { id: crypto.randomUUID(), at: new Date(), ...n };
    setNotifications((prev) => [item, ...prev].slice(0, 30));
  }, []);

  const refresh = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const [inc, resp, anal] = await Promise.all([
        api.incidents("active"),
        api.responders(false),
        api.analytics(),
      ]);
      setIncidents(inc.incidents || []);
      setResponders(resp.responders || []);
      setAnalytics(anal.analytics);
      setDemoMode(false);
      if (!selectedId && inc.incidents?.length) setSelectedId(inc.incidents[0].eventId);
    } catch (e) {
      setDemoMode(true);
      setIncidents(DEMO_INCIDENTS);
      setResponders(DEMO_RESPONDERS);
      setAnalytics({
        total: 24,
        active: 2,
        last24hCount: 8,
        avgResponseMinutes: 7.2,
        byIncidentStatus: { incoming: 1, dispatched: 1, en_route: 0, on_scene: 0, resolved: 22 },
        hourBuckets: Array.from({ length: 24 }, (_, h) => ({ hour: h, count: Math.floor(Math.random() * 4) })),
      });
      if (!selectedId) setSelectedId("demo-1");
      setError(`Demo mode — ${e.message}`);
    } finally {
      setLoading(false);
    }
  }, [selectedId]);

  useEffect(() => {
    refresh();
    const t = setInterval(refresh, 30000);
    return () => clearInterval(t);
  }, []);

  const handleWsMessage = useCallback(
    (msg) => {
      if (msg.type === "notification") {
        pushNotification(msg.payload);
      }
      if (msg.type === "sos:new") {
        const inc = msg.payload;
        setIncidents((prev) => {
          if (prev.some((i) => i.eventId === inc.eventId)) return prev;
          return [{ ...inc, id: inc.eventId, triggeredAt: inc.triggeredAt || new Date().toISOString() }, ...prev];
        });
        setSelectedId(inc.eventId);
        setAnalytics((a) => ({ ...a, active: (a?.active ?? 0) + 1 }));
        pushNotification({
          level: "critical",
          title: "NEW SOS",
          message: inc.victimName || "Victim",
        });
        refresh();
      }
      if (msg.type === "sos:location") {
        const { eventId, latitude, longitude } = msg.payload;
        setIncidents((prev) =>
          prev.map((i) =>
            i.eventId === eventId ? { ...i, latitude: latitude ?? i.latitude, longitude: longitude ?? i.longitude } : i,
          ),
        );
      }
      if (msg.type === "incident:status" || msg.type === "responder:assigned") {
        const { eventId, incidentStatus, responder } = msg.payload;
        setIncidents((prev) =>
          prev.map((i) => {
            if (i.eventId !== eventId) return i;
            return {
              ...i,
              incidentStatus: incidentStatus || i.incidentStatus,
              assignedResponderName: responder?.name || i.assignedResponderName,
              etaMinutes: msg.payload.etaMinutes ?? i.etaMinutes,
            };
          }),
        );
        if (msg.type === "responder:assigned") {
          pushNotification({
            level: "info",
            title: "Responder assigned",
            message: msg.payload.responder?.name || "Unit dispatched",
          });
        }
        refresh();
      }
    },
    [pushNotification, refresh],
  );

  const runLiveDemo = useCallback(async () => {
    try {
      const result = await api.runHackathonDemo("ruralSos");
      pushNotification({
        level: "info",
        title: "Live demo started",
        message: result.message || "Watch the feed and map",
      });
      return result;
    } catch (e) {
      pushNotification({ level: "warning", title: "Demo (offline)", message: e.message });
      const inc = DEMO_INCIDENTS[0];
      handleWsMessage({ type: "sos:new", payload: { ...inc, eventId: `demo_${Date.now()}` } });
      return null;
    }
  }, [pushNotification, handleWsMessage]);

  const [selectedDetail, setSelectedDetail] = useState(null);

  useEffect(() => {
    if (!selectedId || demoMode) {
      setSelectedDetail(null);
      return;
    }
    api.incident(selectedId)
      .then((r) => setSelectedDetail(r.incident))
      .catch(() => setSelectedDetail(null));
  }, [selectedId, demoMode, incidents]);

  const selected =
    selectedDetail ||
    incidents.find((i) => i.eventId === selectedId) ||
    null;

  const updateStatus = async (incidentStatus, notes = "") => {
    if (demoMode) {
      setIncidents((prev) =>
        prev.map((i) => (i.eventId === selectedId ? { ...i, incidentStatus } : i)),
      );
      pushNotification({ level: "info", title: "Status updated (demo)", message: incidentStatus });
      return;
    }
    await api.updateStatus(selectedId, incidentStatus, notes);
    await refresh();
  };

  const assignResponder = async (responderId) => {
    if (demoMode) {
      const r = responders.find((x) => x.id === responderId);
      setIncidents((prev) =>
        prev.map((i) =>
          i.eventId === selectedId
            ? { ...i, incidentStatus: "dispatched", assignedResponderName: r?.name, etaMinutes: 5 }
            : i,
        ),
      );
      pushNotification({ level: "critical", title: "Assigned (demo)", message: r?.name });
      return;
    }
    await api.assign(selectedId, responderId);
    await refresh();
  };

  const optimizeRoute = async () => {
    if (demoMode) {
      pushNotification({ level: "info", title: "Route optimized (demo)", message: "ETA 5 min via Unit 7" });
      return null;
    }
    return api.optimizeRoute(selectedId);
  };

  return {
    incidents,
    responders,
    analytics,
    selected,
    selectedId,
    setSelectedId,
    notifications,
    pushNotification,
    demoMode,
    loading,
    error,
    refresh,
    updateStatus,
    assignResponder,
    optimizeRoute,
    handleWsMessage,
    runLiveDemo,
  };
}
