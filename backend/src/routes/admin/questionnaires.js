const router = require('express').Router();
const { body, param } = require('express-validator');
const { validateRequest } = require('../../middleware/validate');
const { db } = require('../../config/firebase');
const admin = require('firebase-admin');

const TOOLS = ['dass21', 'maas', 'pws18'];

/**
 * GET /api/admin/questionnaires/schedule
 * Returns all 3 unlock dates for each questionnaire tool.
 */
router.get('/schedule', async (req, res) => {
  const result = {};

  await Promise.all(
    TOOLS.map(async (tool) => {
      const doc = await db.collection('questionnaire_control').doc(tool).get();
      result[tool] = doc.exists ? doc.data() : {};
    })
  );

  res.json(result);
});

/**
 * PUT /api/admin/questionnaires/schedule/:tool
 * Updates the unlock timestamps for a specific tool.
 *
 * Body: { attempt_1_date: ISO string, attempt_2_date: ISO string, attempt_3_date: ISO string }
 */
router.put(
  '/schedule/:tool',
  [
    param('tool').isIn(TOOLS),
    body('attempt_1_date').optional().isISO8601(),
    body('attempt_2_date').optional().isISO8601(),
    body('attempt_3_date').optional().isISO8601(),
  ],
  validateRequest,
  async (req, res) => {
    const { tool } = req.params;
    const updates = {};

    ['attempt_1_date', 'attempt_2_date', 'attempt_3_date'].forEach((key) => {
      if (req.body[key]) {
        updates[key] = admin.firestore.Timestamp.fromDate(new Date(req.body[key]));
      }
    });

    if (!Object.keys(updates).length) {
      return res.status(422).json({ error: 'No dates provided.' });
    }

    await db.collection('questionnaire_control').doc(tool).set(updates, { merge: true });
    res.json({ success: true, tool, updated: Object.keys(updates) });
  }
);

/**
 * GET /api/admin/questionnaires/results/:tool
 * Returns all attempts across all users for a specific tool.
 */
router.get(
  '/results/:tool',
  [param('tool').isIn(TOOLS)],
  validateRequest,
  async (req, res) => {
    const { tool } = req.params;
    const snap = await db.collectionGroup(`${tool}_responses`).get();
    const results = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
    res.json(results);
  }
);

module.exports = router;
