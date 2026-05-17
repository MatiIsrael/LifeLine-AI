import { useEffect, useRef, useState } from "react";
import { getDashboardKey } from "../api";

const WS_BASE = import.meta.env.VITE_API_BASE?.replace(/^http/, "ws") || `ws://${window.location.hostname}:8080`;

export function useWebSocket(onMessage) {
  const [connected, setConnected] = useState(false);
  const wsRef = useRef(null);
  const handlerRef = useRef(onMessage);
  handlerRef.current = onMessage;

  useEffect(() => {
    const key = getDashboardKey();
    const url = `${WS_BASE}/ws?key=${encodeURIComponent(key)}`;
    const ws = new WebSocket(url);
    wsRef.current = ws;

    ws.onopen = () => setConnected(true);
    ws.onclose = () => setConnected(false);
    ws.onerror = () => setConnected(false);
    ws.onmessage = (evt) => {
      try {
        const msg = JSON.parse(evt.data);
        handlerRef.current?.(msg);
      } catch (_) {}
    };

    return () => ws.close();
  }, []);

  return { connected };
}
