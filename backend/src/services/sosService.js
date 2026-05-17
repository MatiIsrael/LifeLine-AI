import { admin, db } from "../config/firebaseAdmin.js";
import { notifyLocationUpdate, notifySosTriggered } from "./dashboardService.js";
import { sendEmergencyPush } from "./notificationService.js";

export async function triggerSos({
  uid,
  latitude,
  longitude,
  address = "",
  silent = false,
  triggerType = "manual",
  recordAudio = false,
  audioPath = null,
}) {
  const userDoc = await db.collection("users").doc(uid).get();
  if (!userDoc.exists) {
    throw new Error("Profile not found. Please set up emergency profile first.");
  }

  const contactsSnap = await db.collection("users").doc(uid).collection("contacts").get();
  const contacts = contactsSnap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
  // Use linked Firebase Auth UIDs so trusted contacts receive FCM pushes.
  const contactIds = contacts
    .map((contact) => contact.contactUid)
    .filter((uid) => typeof uid === "string" && uid.length > 0);

  const userData = userDoc.data();
  const emergencyRef = db.collection("emergencies").doc();
  const now = admin.firestore.FieldValue.serverTimestamp();

  await emergencyRef.set({
    uid,
    status: "active",
    incidentStatus: "incoming",
    priority: "high",
    latitude,
    longitude,
    address,
    contactIds,
    silent,
    triggerType,
    recordAudio,
    audioPath,
    victimName: userData.fullName || "Lifeline user",
    triggeredAt: now,
    createdAt: now,
  });

  await emergencyRef.collection("locations").add({
    latitude,
    longitude,
    speed: 0,
    heading: 0,
    recordedAt: now,
  });

  await sendEmergencyPush({
    contactIds,
    senderName: userData.fullName || "A Lifeline user",
    eventId: emergencyRef.id,
    lat: latitude,
    lng: longitude,
    silent,
    triggerType,
  });

  notifySosTriggered({
    eventId: emergencyRef.id,
    uid,
    victimName: userData.fullName || "Lifeline user",
    latitude,
    longitude,
    address,
    triggerType,
    silent,
    status: "active",
    incidentStatus: "incoming",
    priority: "high",
  });

  return { eventId: emergencyRef.id };
}

export async function attachEmergencyAudio({ uid, eventId, audioUrl }) {
  const eventRef = db.collection("emergencies").doc(eventId);
  const eventDoc = await eventRef.get();
  if (!eventDoc.exists) throw new Error("Emergency event not found.");

  const eventData = eventDoc.data();
  if (eventData.uid !== uid) throw new Error("Unauthorized emergency access.");

  await eventRef.update({
    audioUrl,
    recordAudio: true,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

export async function updateSosLocation({ uid, eventId, latitude, longitude, speed = 0, heading = 0 }) {
  const eventRef = db.collection("emergencies").doc(eventId);
  const eventDoc = await eventRef.get();
  if (!eventDoc.exists) throw new Error("Emergency event not found.");

  const eventData = eventDoc.data();
  if (eventData.uid !== uid) throw new Error("Unauthorized emergency access.");
  if (eventData.status !== "active") throw new Error("Emergency event is not active.");

  const now = admin.firestore.FieldValue.serverTimestamp();

  await eventRef.update({
    latitude,
    longitude,
    updatedAt: now,
  });

  await eventRef.collection("locations").add({
    latitude,
    longitude,
    speed,
    heading,
    recordedAt: now,
  });

  notifyLocationUpdate(eventId, { latitude, longitude, speed, heading });
}

export async function resolveSos({ uid, eventId, notes = "" }) {
  const eventRef = db.collection("emergencies").doc(eventId);
  const eventDoc = await eventRef.get();
  if (!eventDoc.exists) throw new Error("Emergency event not found.");

  const eventData = eventDoc.data();
  if (eventData.uid !== uid) throw new Error("Unauthorized emergency access.");

  await eventRef.update({
    status: "resolved",
    incidentStatus: "resolved",
    notes,
    resolvedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}
