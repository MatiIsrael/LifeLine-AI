import { admin, db } from "../config/firebaseAdmin.js";
import { triggerSos } from "./sosService.js";

/**
 * Idempotent sync for offline-queued SOS events (localId + version).
 */
export async function syncQueuedSos({ uid, localId, version = 1, payload = {}, serverEventId }) {
  if (!localId) throw new Error("localId is required for sync.");

  const mapRef = db.collection("offline_sync").doc(`${uid}_${localId}`);
  const existing = await mapRef.get();

  if (existing.exists) {
    const data = existing.data();
    return {
      eventId: data.eventId,
      serverVersion: data.serverVersion ?? version,
      conflictResolution: "duplicate_local_id",
    };
  }

  if (serverEventId) {
    const eventRef = db.collection("emergencies").doc(serverEventId);
    const eventDoc = await eventRef.get();
    if (eventDoc.exists && eventDoc.data().uid === uid) {
      await mapRef.set({
        uid,
        localId,
        eventId: serverEventId,
        serverVersion: version,
        syncedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      return {
        eventId: serverEventId,
        serverVersion: version,
        conflictResolution: "existing_server_event",
      };
    }
  }

  const {
    latitude,
    longitude,
    address = "",
    silent = false,
    triggerType = "manual",
    recordAudio = false,
    audioPath = null,
  } = payload;

  const result = await triggerSos({
    uid,
    latitude,
    longitude,
    address,
    silent,
    triggerType,
    recordAudio,
    audioPath,
  });

  await mapRef.set({
    uid,
    localId,
    eventId: result.eventId,
    clientVersion: version,
    serverVersion: version + 1,
    syncedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return {
    eventId: result.eventId,
    serverVersion: version + 1,
    conflictResolution: "server_accepted",
  };
}
