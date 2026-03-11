const router = require("express").Router();
const { body } = require("express-validator");
const { validateRequest } = require("../../middleware/validate");
const {
  sendMulticast,
  sendToTopic,
  getAllActiveTokens,
} = require("../../services/notificationService");
const logger = require("../../config/logger");

/**
 * POST /api/admin/notifications/broadcast
 * Sends a push notification to ALL registered users.
 *
 * Body: { title: string, body: string, data?: object }
 */
router.post(
  "/broadcast",
  [
    body("title").isString().trim().notEmpty().isLength({ max: 100 }),
    body("body").isString().trim().notEmpty().isLength({ max: 300 }),
    body("data").optional().isObject(),
  ],
  validateRequest,
  async (req, res) => {
    const { title, body: msgBody, data = {} } = req.body;

    const tokens = await getAllActiveTokens();
    if (!tokens.length) {
      return res.json({
        success: true,
        successCount: 0,
        failureCount: 0,
        message: "No tokens found.",
      });
    }

    const result = await sendMulticast(tokens, title, msgBody, data);
    logger.info("Admin broadcast sent", result);
    res.json({ success: true, ...result });
  },
);

/**
 * POST /api/admin/notifications/topic
 * Sends a push notification to a specific FCM topic.
 * Use topics like: 'all_users', 'en_users', 'si_users'.
 *
 * Body: { topic: string, title: string, body: string, data?: object }
 */
router.post(
  "/topic",
  [
    body("topic")
      .isString()
      .trim()
      .notEmpty()
      .matches(/^[a-zA-Z0-9_-]+$/),
    body("title").isString().trim().notEmpty().isLength({ max: 100 }),
    body("body").isString().trim().notEmpty().isLength({ max: 300 }),
    body("data").optional().isObject(),
  ],
  validateRequest,
  async (req, res) => {
    const { topic, title, body: msgBody, data = {} } = req.body;

    try {
      const messageId = await sendToTopic(topic, title, msgBody, data);
      res.json({ success: true, messageId });
    } catch (err) {
      logger.error("Topic push failed", { error: err.message });
      res.status(502).json({ error: "Failed to send notification." });
    }
  },
);

module.exports = router;
