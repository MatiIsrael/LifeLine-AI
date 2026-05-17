import { admin, db } from "../config/firebaseAdmin.js";
import { DEMO_SAFETY_DATA } from "../data/demoSafetyData.js";

let cache = { loadedAt: 0, data: null };
const CACHE_TTL_MS = 60_000;

function serializeTs(v) {
  if (!v) return null;
  if (v.toDate) return v.toDate().toISOString();
  return v;
}

async function loadFromFirestore() {
  const [incidentsSnap, reportsSnap, patternsSnap] = await Promise.all([
    db.collection("safety_incidents").limit(500).get(),
    db.collection("safety_reports").orderBy("createdAt", "desc").limit(300).get(),
    db.collection("gps_patterns").limit(400).get(),
  ]);

  const incidents = incidentsSnap.docs.map((d) => ({ id: d.id, ...d.data() }));
  const reports = reportsSnap.docs.map((d) => ({ id: d.id, ...d.data() }));
  const gpsPatterns = patternsSnap.docs.map((d) => ({ id: d.id, ...d.data() }));

  if (incidents.length === 0 && reports.length === 0) {
    return DEMO_SAFETY_DATA;
  }

  return {
    incidents: incidents.map((i) => ({
      ...i,
      recordedAt: serializeTs(i.recordedAt),
    })),
    reports: reports.map((r) => ({
      ...r,
      createdAt: serializeTs(r.createdAt),
    })),
    gpsPatterns,
    source: "firestore",
  };
}

export async function getSafetyDataset() {
  const now = Date.now();
  if (cache.data && now - cache.loadedAt < CACHE_TTL_MS) {
    return cache.data;
  }

  try {
    cache.data = await loadFromFirestore();
  } catch {
    cache.data = DEMO_SAFETY_DATA;
  }
  cache.loadedAt = now;
  return cache.data;
}

export async function addUserReport({ uid, latitude, longitude, category, description }) {
  const ref = db.collection("safety_reports").doc();
  const payload = {
    uid: uid || "anonymous",
    latitude,
    longitude,
    category: category || "unsafe_area",
    description: description || "",
    verified: false,
    weight: 1.2,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };
  await ref.set(payload);
  cache.loadedAt = 0;
  return { id: ref.id, ...payload };
}

export function invalidateCache() {
  cache.loadedAt = 0;
}
