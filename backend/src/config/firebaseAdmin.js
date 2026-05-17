import { existsSync, readFileSync } from "fs";
import path from "path";
import admin from "firebase-admin";

let db = null;
let messaging = null;
export let firebaseEnabled = false;

const credPath = process.env.GOOGLE_APPLICATION_CREDENTIALS || "./serviceAccountKey.json";
const resolved = path.isAbsolute(credPath) ? credPath : path.resolve(process.cwd(), credPath);

if (existsSync(resolved)) {
  try {
    const serviceAccount = JSON.parse(readFileSync(resolved, "utf8"));
    if (!admin.apps.length) {
      admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
    }
    db = admin.firestore();
    messaging = admin.messaging();
    firebaseEnabled = true;
    console.log("Firebase Admin connected");
  } catch (err) {
    console.warn("Firebase init failed:", err.message, "— using demo mode");
  }
} else {
  console.warn("No serviceAccountKey.json — dashboard uses demo data; WebSocket + safety APIs still work");
}

export { admin, db, messaging };
