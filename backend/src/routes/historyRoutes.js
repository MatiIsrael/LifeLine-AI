import { Router } from "express";
import { db } from "../config/firebaseAdmin.js";

const router = Router();

router.get("/", async (req, res) => {
  try {
    const uid = req.user.uid;

    const snap = await db
      .collection("emergencies")
      .where("uid", "==", uid)
      .orderBy("triggeredAt", "desc")
      .limit(50)
      .get();

    const history = snap.docs.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        ...data,
        triggeredAt: data.triggeredAt?.toDate?.()?.toISOString?.() ?? null,
        resolvedAt: data.resolvedAt?.toDate?.()?.toISOString?.() ?? null,
      };
    });

    return res.json({ history });
  } catch (error) {
    return res.status(500).json({ message: error.message });
  }
});

export default router;
