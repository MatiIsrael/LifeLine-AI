import { WebSocketServer } from "ws";

/** @type {WebSocketServer | null} */
let wss = null;

const clients = new Set();

export function initRealtimeHub(server) {
  wss = new WebSocketServer({ server, path: "/ws" });

  wss.on("connection", (socket, req) => {
    const url = new URL(req.url || "", `http://${req.headers.host}`);
    const key = url.searchParams.get("key");
    const expected = process.env.DASHBOARD_API_KEY || "lifeline-dashboard-dev";

    if (key !== expected) {
      socket.close(4001, "Unauthorized");
      return;
    }

    clients.add(socket);
    socket.send(JSON.stringify({ type: "connected", at: new Date().toISOString() }));

    socket.on("close", () => clients.delete(socket));
    socket.on("error", () => clients.delete(socket));
  });

  console.log("WebSocket hub ready at /ws");
}

export function broadcast(event, payload) {
  const message = JSON.stringify({
    type: event,
    payload,
    at: new Date().toISOString(),
  });

  for (const client of clients) {
    if (client.readyState === 1) {
      client.send(message);
    }
  }
}

export function getConnectedClients() {
  return clients.size;
}
