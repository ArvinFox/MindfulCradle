const router = require('express').Router();
const { body } = require('express-validator');
const { validateRequest } = require('../middleware/validate');
const { verifyToken } = require('../middleware/auth');
const { sendToToken, sendMulticast, sendToTopic, getAllActiveTokens } = require('../services/notificationService');
const { db } = require('../config/firebase');
const logger = require('../config/logger');

router.use(verifyToken);

/**
 * PUT /api/notifications/token
 * Registers or updates the device FCM token for the authenticated user.
 *
 * Body: { token: string }
 */
router.put(
  '/token',
  [body('token').isString().trim().notEmpty()],
  validateRequest,
  async (req, res) => {
    const uid = req.user.uid;
    await db.collection('users').doc(uid).update({ fcmToken: req.body.token });
    res.json({ success: true });
  }
);

/**
 * POST /api/notifications/test
 * Sends a test notification to the authenticated user's own device.
 * Useful for debugging notification delivery.
 */
router.post('/test', async (req, res) => {
  const uid = req.user.uid;
  const userDoc = await db.collection('users').doc(uid).get();
  const fcmToken = userDoc.data()?.fcmToken;

  if (!fcmToken) {
    return res.status(400).json({ error: 'No FCM token registered for this account.' });
  }

  try {
    await sendToToken(fcmToken, 'MindfulCradle', 'Notifications are working!', {
      type: 'test',
    });
    res.json({ success: true });
  } catch (err) {
    logger.error('Test notification failed', { error: err.message });
    res.status(502).json({ error: 'Could not send test notification.' });
  }
});

module.exports = router;
