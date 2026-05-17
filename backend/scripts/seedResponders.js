import "dotenv/config";
import { db, admin } from "../src/config/firebaseAdmin.js";

const responders = [
  { name: "City Ambulance Unit 7", type: "ambulance", phone: "+440001", latitude: 51.5074, longitude: -0.1278, status: "available" },
  { name: "Metro Police Patrol 12", type: "police", phone: "+440002", latitude: 51.515, longitude: -0.12, status: "available" },
  { name: "St. Mary's ER Team", type: "hospital", phone: "+440003", latitude: 51.499, longitude: -0.135, status: "available" },
  { name: "Rural EMS Unit 3", type: "ambulance", phone: "+440004", latitude: 51.52, longitude: -0.11, status: "available" },
  { name: "Coordinator Alpha", type: "coordinator", phone: "+440005", latitude: 51.505, longitude: -0.115, status: "available" },
];

async function seed() {
  const batch = db.batch();
  responders.forEach((r) => {
    const ref = db.collection("responders").doc();
    batch.set(ref, { ...r, updatedAt: admin.firestore.FieldValue.serverTimestamp() });
  });
  await batch.commit();
  console.log(`Seeded ${responders.length} responders.`);
  process.exit(0);
}

seed().catch((e) => {
  console.error(e);
  process.exit(1);
});
