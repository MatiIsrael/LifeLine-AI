import { db, messaging } from "../config/firebaseAdmin.js";

export async function getTokensForUser(uid) {
  const tokenDoc = await db.collection("deviceTokens").doc(uid).get();
  if (!tokenDoc.exists) return [];
  const { tokens = [] } = tokenDoc.data();
  return tokens;
}

export async function getTokensForContacts(contactIds = []) {
  if (!Array.isArray(contactIds) || contactIds.length === 0) return [];

  // Contact IDs are Firebase Auth UIDs if contacts are app users.
  const tokenFetches = contactIds.map((contactUid) => getTokensForUser(contactUid));
  const tokenLists = await Promise.all(tokenFetches);
  return [...new Set(tokenLists.flat())];
}

export async function sendEmergencyPush({
  contactIds,
  senderName,
  eventId,
  lat,
  lng,
  silent = false,
  triggerType = "manual",
}) {
  const tokens = await getTokensForContacts(contactIds);
  if (!tokens.length) return { successCount: 0, failureCount: 0 };

  const dataPayload = {
    type: "SOS_ALERT",
    eventId,
    latitude: String(lat),
    longitude: String(lng),
    silent: String(silent),
    triggerType,
  };

  const payload = {
    tokens,
    data: dataPayload,
  };

  if (!silent) {
    payload.notification = {
      title: "SOS Alert",
      body: `${senderName} triggered an emergency alert (${triggerType}).`,
    };
  }

  const response = await messaging.sendEachForMulticast(payload);

  return {
    successCount: response.successCount,
    failureCount: response.failureCount,
  };
}
