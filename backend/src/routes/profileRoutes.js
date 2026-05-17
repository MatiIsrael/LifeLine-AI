import { Router } from "express";
import { admin, db } from "../config/firebaseAdmin.js";

const router = Router();

router.get("/", async (req, res) => {
  try {
    const uid = req.user.uid;
    const userDoc = await db.collection("users").doc(uid).get();
    const contactsSnap = await db.collection("users").doc(uid).collection("contacts").get();

    return res.json({
      profile: userDoc.exists ? userDoc.data() : null,
      contacts: contactsSnap.docs.map((doc) => ({ id: doc.id, ...doc.data() })),
    });
  } catch (error) {
    return res.status(500).json({ message: error.message });
  }
});

router.post("/", async (req, res) => {
  try {
    const uid = req.user.uid;
    const { fullName, phoneNumber, bloodGroup, medicalNotes } = req.body;
    const now = admin.firestore.FieldValue.serverTimestamp();

    await db.collection("users").doc(uid).set(
      {
        email: req.user.email || "",
        fullName,
        phoneNumber,
        bloodGroup,
        medicalNotes,
        updatedAt: now,
        createdAt: now,
      },
      { merge: true }
    );

    return res.json({ message: "Profile saved successfully." });
  } catch (error) {
    return res.status(500).json({ message: error.message });
  }
});

router.post("/contact", async (req, res) => {
  try {
    const uid = req.user.uid;
    const { name, phoneNumber, relationship, contactUid = "", contactEmail = "" } = req.body;
    const now = admin.firestore.FieldValue.serverTimestamp();

    const contactsCollection = db.collection("users").doc(uid).collection("contacts");
    const contactRef = contactUid ? contactsCollection.doc(contactUid) : contactsCollection.doc();
    await contactRef.set({
      name,
      phoneNumber,
      relationship,
      contactUid,
      contactEmail,
      createdAt: now,
    });

    return res.json({ message: "Contact added successfully.", contactId: contactRef.id });
  } catch (error) {
    return res.status(500).json({ message: error.message });
  }
});

router.post("/contact/link", async (req, res) => {
  try {
    const { email } = req.body;
    if (!email) return res.status(400).json({ message: "Email is required." });

    const user = await admin.auth().getUserByEmail(email);
    return res.json({ contactUid: user.uid, email: user.email });
  } catch (error) {
    return res.status(404).json({
      message: "No Lifeline user found for that email. Ask them to register first.",
    });
  }
});

export default router;
