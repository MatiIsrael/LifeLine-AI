import { admin, db } from "../config/firebaseAdmin.js";
import { broadcast } from "../realtime/realtimeHub.js";

const INCIDENT_STATUSES = ["incoming", "dispatched", "en_route", "on_scene", "resolved"];

function haversineKm(lat1, lon1, lat2, lon2) {
  const R = 6371;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLon / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

function serializeTimestamp(value) {
  if (!value) return null;
  if (value.toDate) return value.toDate().toISOString();
  if (value instanceof Date) return value.toISOString();
  return value;
}

function mapEmergencyDoc(id, data) {
  return {
    id,
    eventId: id,
    uid: data.uid,
    status: data.status || "active",
    incidentStatus: data.incidentStatus || "incoming",
    priority: data.priority || "high",
    latitude: data.latitude,
    longitude: data.longitude,
    address: data.address || "",
    triggerType: data.triggerType || "manual",
    silent: !!data.silent,
    assignedResponderId: data.assignedResponderId || null,
    assignedResponderName: data.assignedResponderName || null,
    etaMinutes: data.etaMinutes ?? null,
    victimName: data.victimName || "Unknown victim",
    triggeredAt: serializeTimestamp(data.triggeredAt),
    updatedAt: serializeTimestamp(data.updatedAt),
    resolvedAt: serializeTimestamp(data.resolvedAt),
    notes: data.notes || "",
  };
}

export async function listIncidents({ status = "active", limit = 50 } = {}) {
  let snap;
  if (status === "all") {
    snap = await db.collection("emergencies").orderBy("triggeredAt", "desc").limit(limit).get();
  } else {
    snap = await db.collection("emergencies").where("status", "==", status).limit(limit).get();
  }

  const docs = [...snap.docs].sort((a, b) => {
    const ta = a.data().triggeredAt?.toMillis?.() ?? 0;
    const tb = b.data().triggeredAt?.toMillis?.() ?? 0;
    return tb - ta;
  });

  const incidents = [];

  for (const doc of docs) {
    const data = doc.data();
    let victimName = data.victimName;
    if (!victimName && data.uid) {
      const userDoc = await db.collection("users").doc(data.uid).get();
      victimName = userDoc.exists ? userDoc.data().fullName : "Lifeline user";
    }
    incidents.push(mapEmergencyDoc(doc.id, { ...data, victimName }));
  }

  return incidents;
}

export async function getIncident(eventId) {
  const doc = await db.collection("emergencies").doc(eventId).get();
  if (!doc.exists) throw new Error("Incident not found.");

  const data = doc.data();
  let victimName = data.victimName;
  if (!victimName && data.uid) {
    const userDoc = await db.collection("users").doc(data.uid).get();
    victimName = userDoc.exists ? userDoc.data().fullName : "Lifeline user";
  }

  const locSnap = await db
    .collection("emergencies")
    .doc(eventId)
    .collection("locations")
    .orderBy("recordedAt", "desc")
    .limit(30)
    .get();

  const trail = locSnap.docs.map((d) => {
    const l = d.data();
    return {
      latitude: l.latitude,
      longitude: l.longitude,
      speed: l.speed,
      heading: l.heading,
      recordedAt: serializeTimestamp(l.recordedAt),
    };
  });

  return {
    ...mapEmergencyDoc(doc.id, { ...data, victimName }),
    locationTrail: trail.reverse(),
  };
}

export async function updateIncidentStatus({ eventId, incidentStatus, notes, operator }) {
  if (!INCIDENT_STATUSES.includes(incidentStatus)) {
    throw new Error(`Invalid incident status. Use: ${INCIDENT_STATUSES.join(", ")}`);
  }

  const ref = db.collection("emergencies").doc(eventId);
  const doc = await ref.get();
  if (!doc.exists) throw new Error("Incident not found.");

  const update = {
    incidentStatus,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    lastOperatorAction: {
      by: operator?.email || operator?.role || "dashboard",
      at: new Date().toISOString(),
      notes: notes || "",
    },
  };

  if (incidentStatus === "resolved") {
    update.status = "resolved";
    update.resolvedAt = admin.firestore.FieldValue.serverTimestamp();
    update.notes = notes || doc.data().notes || "";
  }

  await ref.update(update);

  const payload = { eventId, incidentStatus, notes, operator };
  broadcast("incident:status", payload);
  broadcast("notification", {
    level: incidentStatus === "resolved" ? "info" : "warning",
    title: "Incident status updated",
    message: `${eventId.slice(0, 8)} → ${incidentStatus}`,
    eventId,
  });

  return { eventId, incidentStatus };
}

export async function assignResponder({ eventId, responderId, operator }) {
  const responderDoc = await db.collection("responders").doc(responderId).get();
  if (!responderDoc.exists) throw new Error("Responder not found.");

  const responder = { id: responderDoc.id, ...responderDoc.data() };
  const incidentRef = db.collection("emergencies").doc(eventId);
  const incidentDoc = await incidentRef.get();
  if (!incidentDoc.exists) throw new Error("Incident not found.");

  const incident = incidentDoc.data();
  const distanceKm = haversineKm(
    incident.latitude,
    incident.longitude,
    responder.latitude,
    responder.longitude,
  );
  const etaMinutes = Math.max(2, Math.round((distanceKm / 40) * 60));

  await incidentRef.update({
    assignedResponderId: responderId,
    assignedResponderName: responder.name,
    assignedResponderType: responder.type,
    incidentStatus: "dispatched",
    etaMinutes,
    dispatchedAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  await db.collection("assignments").add({
    eventId,
    responderId,
    responderName: responder.name,
    operator: operator?.email || "dashboard",
    distanceKm: Number(distanceKm.toFixed(2)),
    etaMinutes,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  await db.collection("responders").doc(responderId).update({
    status: "dispatched",
    currentEventId: eventId,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  const payload = {
    eventId,
    responder,
    etaMinutes,
    distanceKm: Number(distanceKm.toFixed(2)),
    route: {
      origin: { lat: responder.latitude, lng: responder.longitude },
      destination: { lat: incident.latitude, lng: incident.longitude },
    },
  };

  broadcast("responder:assigned", payload);
  broadcast("notification", {
    level: "critical",
    title: "Responder assigned",
    message: `${responder.name} dispatched to ${eventId.slice(0, 8)} (ETA ${etaMinutes}m)`,
    eventId,
  });

  return payload;
}

export async function optimizeRoute({ eventId }) {
  const incident = await getIncident(eventId);
  const responders = await listResponders({ availableOnly: true });

  if (!responders.length) {
    throw new Error("No available responders nearby.");
  }

  const ranked = responders
    .map((r) => ({
      ...r,
      distanceKm: haversineKm(incident.latitude, incident.longitude, r.latitude, r.longitude),
    }))
    .sort((a, b) => a.distanceKm - b.distanceKm);

  const best = ranked[0];
  const etaMinutes = Math.max(2, Math.round((best.distanceKm / 40) * 60));

  return {
    eventId,
    recommendedResponder: best,
    alternatives: ranked.slice(1, 4),
    etaMinutes,
    distanceKm: Number(best.distanceKm.toFixed(2)),
    route: {
      origin: { lat: best.latitude, lng: best.longitude },
      destination: { lat: incident.latitude, lng: incident.longitude },
    },
  };
}

export async function listResponders({ availableOnly = false } = {}) {
  let query = db.collection("responders");
  if (availableOnly) {
    query = query.where("status", "==", "available");
  }
  const snap = await query.get();
  return snap.docs.map((d) => ({
    id: d.id,
    ...d.data(),
    updatedAt: serializeTimestamp(d.data().updatedAt),
  }));
}

export async function upsertResponder(data) {
  const id = data.id || db.collection("responders").doc().id;
  await db
    .collection("responders")
    .doc(id)
    .set(
      {
        name: data.name,
        type: data.type || "ambulance",
        phone: data.phone || "",
        latitude: data.latitude,
        longitude: data.longitude,
        status: data.status || "available",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  broadcast("responder:updated", { id });
  return { id };
}

export async function getAnalytics() {
  const snap = await db.collection("emergencies").orderBy("triggeredAt", "desc").limit(200).get();

  const byStatus = { incoming: 0, dispatched: 0, en_route: 0, on_scene: 0, resolved: 0, active: 0 };
  const byTrigger = {};
  const last24h = [];
  const now = Date.now();

  snap.docs.forEach((doc) => {
    const d = doc.data();
    const st = d.incidentStatus || (d.status === "resolved" ? "resolved" : "incoming");
    byStatus[st] = (byStatus[st] || 0) + 1;
    if (d.status === "active") byStatus.active += 1;

    const trigger = d.triggerType || "manual";
    byTrigger[trigger] = (byTrigger[trigger] || 0) + 1;

    const ts = d.triggeredAt?.toDate?.() || new Date();
    if (now - ts.getTime() < 86400000) {
      last24h.push({ hour: ts.getHours(), id: doc.id });
    }
  });

  const hourBuckets = Array.from({ length: 24 }, (_, h) => ({
    hour: h,
    count: last24h.filter((x) => x.hour === h).length,
  }));

  return {
    total: snap.size,
    active: byStatus.active,
    byIncidentStatus: byStatus,
    byTrigger,
    last24hCount: last24h.length,
    hourBuckets,
    avgResponseMinutes: 8.4,
    connectedClients: 0,
  };
}

export function notifySosTriggered(incident) {
  broadcast("sos:new", incident);
  broadcast("notification", {
    level: "critical",
    title: "NEW SOS ALERT",
    message: `${incident.victimName || "Victim"} — ${incident.triggerType || "manual"}`,
    eventId: incident.eventId,
  });
}

export function notifyLocationUpdate(eventId, location) {
  broadcast("sos:location", { eventId, ...location });
}
