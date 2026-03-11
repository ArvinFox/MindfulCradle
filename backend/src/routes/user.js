const router = require("express").Router();
const { body } = require("express-validator");
const { validateRequest } = require("../middleware/validate");
const { verifyToken } = require("../middleware/auth");
const { db, auth } = require("../config/firebase");
const logger = require("../config/logger");

router.use(verifyToken);

/**
 * GET /api/user/profile
 * Returns the authenticated user's profile from Firestore.
 */
router.get("/profile", async (req, res) => {
  const uid = req.user.uid;

  const doc = await db.collection("users").doc(uid).get();
  if (!doc.exists) return res.status(404).json({ error: "User not found." });

  res.json({ id: doc.id, ...doc.data() });
});

/**
 * PUT /api/user/profile
 * Updates allowed profile fields. Prevents uid/email/achievements tampering.
 *
 * Body: { fullName?, age?, residence?, pregnancyMonth?, ... }
 */
const ALLOWED_PROFILE_FIELDS = [
  "fullName",
  "age",
  "residence",
  "pregnancyMonth",
  "firstTimeMother",
  "employed",
  "obstetricComplication",
  "psychologicalSupport",
  "distressingEvents",
  "practicedMindfulness",
  "mindfulnessDuration",
  "isUserRegistrationComplete",
];

router.put(
  "/profile",
  [
    body("fullName")
      .optional()
      .isString()
      .trim()
      .isLength({ min: 1, max: 100 }),
  ],
  validateRequest,
  async (req, res) => {
    const uid = req.user.uid;
    const updates = {};

    ALLOWED_PROFILE_FIELDS.forEach((field) => {
      if (req.body[field] !== undefined) updates[field] = req.body[field];
    });

    if (!Object.keys(updates).length) {
      return res.status(422).json({ error: "No valid fields to update." });
    }

    await db.collection("users").doc(uid).update(updates);
    res.json({ success: true });
  },
);

/**
 * PUT /api/user/fcm-token
 * Saves the device FCM token so the server can send targeted pushes.
 *
 * Body: { token: string }
 */
router.put(
  "/fcm-token",
  [body("token").isString().trim().notEmpty()],
  validateRequest,
  async (req, res) => {
    const uid = req.user.uid;
    await db.collection("users").doc(uid).update({ fcmToken: req.body.token });
    res.json({ success: true });
  },
);

/**
 * GET /api/user/export
 * Server-side GDPR data export. Returns all user data as JSON.
 * (The Flutter app can trigger this and display/save the result.)
 */
router.get("/export", async (req, res) => {
  const uid = req.user.uid;

  const [userDoc, dass21Snap, maasSnap, pws18Snap, chatSnap] =
    await Promise.all([
      db.collection("users").doc(uid).get(),
      db.collection("users").doc(uid).collection("dass21_responses").get(),
      db.collection("users").doc(uid).collection("maas_responses").get(),
      db.collection("users").doc(uid).collection("pws18_responses").get(),
      db.collection("users").doc(uid).collection("chat_sessions").get(),
    ]);

  const exportData = {
    profile: userDoc.data(),
    dass21Responses: dass21Snap.docs.map((d) => d.data()),
    maasResponses: maasSnap.docs.map((d) => d.data()),
    pws18Responses: pws18Snap.docs.map((d) => d.data()),
    chatSessionCount: chatSnap.size,
    exportedAt: new Date().toISOString(),
  };

  res.setHeader(
    "Content-Disposition",
    'attachment; filename="mindfulcradle_data_export.json"',
  );
  res.json(exportData);
});

/**
 * DELETE /api/user/account
 * Permanently deletes all user data from Firestore and the Auth record.
 * Uses the Admin SDK — safe and atomic from the server.
 */
router.delete("/account", async (req, res) => {
  const uid = req.user.uid;

  try {
    const userRef = db.collection("users").doc(uid);

    // Delete all sub-collections
    const subCollections = [
      "dass21_responses",
      "maas_responses",
      "pws18_responses",
      "videoProgress",
      "chat_sessions",
    ];

    for (const col of subCollections) {
      const snap = await userRef.collection(col).get();
      const batch = db.batch();
      snap.docs.forEach((d) => batch.delete(d.ref));
      await batch.commit();

      // For chat_sessions, also delete nested messages
      if (col === "chat_sessions") {
        for (const session of snap.docs) {
          const msgSnap = await session.ref.collection("messages").get();
          const msgBatch = db.batch();
          msgSnap.docs.forEach((m) => msgBatch.delete(m.ref));
          await msgBatch.commit();
        }
      }
    }

    // Delete user document and Auth record
    await userRef.delete();
    await auth.deleteUser(uid);

    logger.info("Account deleted", { uid });
    res.json({ success: true });
  } catch (err) {
    logger.error("Account deletion error", { uid, error: err.message });
    res.status(500).json({ error: "Account deletion failed." });
  }
});

module.exports = router;
