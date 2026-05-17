import "dotenv/config";
import { admin, db } from "../src/config/firebaseAdmin.js";
import { DEMO_SAFETY_DATA } from "../src/data/demoSafetyData.js";

async function seed() {
  const batch = db.batch();
  let n = 0;

  for (const inc of DEMO_SAFETY_DATA.incidents) {
    const ref = db.collection("safety_incidents").doc();
    batch.set(ref, {
      ...inc,
      recordedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    n++;
  }

  for (const rep of DEMO_SAFETY_DATA.reports) {
    const ref = db.collection("safety_reports").doc();
    batch.set(ref, {
      ...rep,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    n++;
  }

  for (const pat of DEMO_SAFETY_DATA.gpsPatterns) {
    const ref = db.collection("gps_patterns").doc();
    batch.set(ref, { ...pat, updatedAt: admin.firestore.FieldValue.serverTimestamp() });
    n++;
  }

  await batch.commit();
  console.log(`Seeded ${n} safety records.`);
  process.exit(0);
}

seed().catch((e) => {
  console.error(e);
  process.exit(1);
});
