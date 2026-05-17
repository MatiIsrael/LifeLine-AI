import { Router } from "express";
import { admin, db } from "../config/firebaseAdmin.js";

const router = Router();

router.post("/device-token", async (req, res) => {
  try {
    const uid = req.user.uid;
    const { token } = req.body;

    if (!token) return res.status(400).json({ message: "Missing token." });

    await db.collection("deviceTokens").doc(uid).set(
      {
        tokens: admin.firestore.FieldValue.arrayUnion(token),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    return res.json({ message: "Device token registered." });
  } catch (error) {
    return res.status(500).json({ message: error.message });
  }
});

export default router;
