import { Router } from "express";

const router = Router();

router.get("/me", (req, res) => {
  return res.json({
    uid: req.user.uid,
    email: req.user.email || "",
    phoneNumber: req.user.phone_number || "",
  });
});

export default router;
