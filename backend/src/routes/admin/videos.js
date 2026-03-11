const router = require("express").Router();
const { body, param } = require("express-validator");
const { validateRequest } = require("../../middleware/validate");
const { db } = require("../../config/firebase");

/**
 * GET /api/admin/videos
 * Lists all meditation videos sorted by session number.
 */
router.get("/", async (req, res) => {
  const snap = await db
    .collection("videos")
    .orderBy("sessionNumber", "asc")
    .get();
  const videos = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
  res.json(videos);
});

/**
 * POST /api/admin/videos
 * Adds a new meditation video.
 *
 * Body: { title, titleSi, youtubeId, youtubeIdSi, duration, sessionNumber }
 */
router.post(
  "/",
  [
    body("title").isString().trim().notEmpty(),
    body("titleSi").isString().trim().notEmpty(),
    body("youtubeId").isString().trim().notEmpty(),
    body("youtubeIdSi").isString().trim().notEmpty(),
    body("duration").isInt({ min: 1 }),
    body("sessionNumber").isInt({ min: 1 }),
  ],
  validateRequest,
  async (req, res) => {
    const { title, titleSi, youtubeId, youtubeIdSi, duration, sessionNumber } =
      req.body;

    const ref = await db.collection("videos").add({
      title,
      titleSi,
      youtubeId,
      youtubeIdSi,
      duration,
      sessionNumber,
    });

    res.status(201).json({ id: ref.id });
  },
);

/**
 * PUT /api/admin/videos/:id
 * Updates a video document. Only sends the fields provided.
 */
router.put(
  "/:id",
  [
    param("id").isString().notEmpty(),
    body("title").optional().isString().trim(),
    body("titleSi").optional().isString().trim(),
    body("youtubeId").optional().isString().trim(),
    body("youtubeIdSi").optional().isString().trim(),
    body("duration").optional().isInt({ min: 1 }),
    body("sessionNumber").optional().isInt({ min: 1 }),
  ],
  validateRequest,
  async (req, res) => {
    const ALLOWED = [
      "title",
      "titleSi",
      "youtubeId",
      "youtubeIdSi",
      "duration",
      "sessionNumber",
    ];
    const updates = {};
    ALLOWED.forEach((f) => {
      if (req.body[f] !== undefined) updates[f] = req.body[f];
    });

    if (!Object.keys(updates).length) {
      return res.status(422).json({ error: "No valid fields to update." });
    }

    await db.collection("videos").doc(req.params.id).update(updates);
    res.json({ success: true });
  },
);

/**
 * DELETE /api/admin/videos/:id
 * Removes a video document.
 */
router.delete(
  "/:id",
  [param("id").isString().notEmpty()],
  validateRequest,
  async (req, res) => {
    await db.collection("videos").doc(req.params.id).delete();
    res.json({ success: true });
  },
);

module.exports = router;
