const router = require('express').Router();
const { body } = require('express-validator');
const { validateRequest } = require('../middleware/validate');
const { chatLimiter } = require('../middleware/rateLimiter');
const { verifyToken } = require('../middleware/auth');
const { generateAnswer, streamAnswer } = require('../services/geminiService');
const { db } = require('../config/firebase');
const logger = require('../config/logger');

// All chat routes require authentication
router.use(verifyToken);

/**
 * POST /api/chat
 * One-shot chat message. Returns the full AI response.
 *
 * Body: { message: string, sessionId?: string, language?: 'en'|'si' }
 */
router.post(
  '/',
  chatLimiter,
  [
    body('message').isString().trim().notEmpty().isLength({ max: 2000 }),
    body('language').optional().isIn(['en', 'si']),
    body('sessionId').optional().isString().trim(),
  ],
  validateRequest,
  async (req, res) => {
    const { message, language = 'en', sessionId } = req.body;
    const uid = req.user.uid;

    // Fetch recent history from Firestore if a sessionId is provided
    let history = [];
    if (sessionId) {
      try {
        const snap = await db
          .collection('users')
          .doc(uid)
          .collection('chat_sessions')
          .doc(sessionId)
          .collection('messages')
          .orderBy('timestamp', 'asc')
          .limitToLast(6)
          .get();
        history = snap.docs.map((d) => d.data());
      } catch (err) {
        logger.warn('Could not load chat history', { sessionId, error: err.message });
      }
    }

    try {
      const answer = await generateAnswer(message, history, language);
      res.json({ answer });
    } catch (err) {
      logger.error('Chat error', { error: err.message });
      res.status(502).json({ error: 'AI service unavailable. Please try again.' });
    }
  }
);

/**
 * GET /api/chat/stream
 * SSE streaming chat. Client receives Server-Sent Events.
 *
 * Query params: message, language?, sessionId?
 */
router.get('/stream', chatLimiter, async (req, res) => {
  const { message, language = 'en', sessionId } = req.query;
  const uid = req.user.uid;

  if (!message || typeof message !== 'string' || message.length > 2000) {
    return res.status(422).json({ error: 'Invalid message parameter.' });
  }

  // SSE headers
  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('Connection', 'keep-alive');
  res.flushHeaders();

  let history = [];
  if (sessionId) {
    try {
      const snap = await db
        .collection('users')
        .doc(uid)
        .collection('chat_sessions')
        .doc(sessionId)
        .collection('messages')
        .orderBy('timestamp', 'asc')
        .limitToLast(6)
        .get();
      history = snap.docs.map((d) => d.data());
    } catch (err) {
      logger.warn('Could not load chat history for stream', { sessionId, error: err.message });
    }
  }

  try {
    await streamAnswer(message, history, language, res);
  } catch (err) {
    logger.error('Chat stream error', { error: err.message });
    res.write(`data: ${JSON.stringify({ error: 'AI service error' })}\n\n`);
    res.end();
  }
});

/**
 * GET /api/chat/sessions
 * Returns the user's chat session list (metadata only).
 */
router.get('/sessions', async (req, res) => {
  const uid = req.user.uid;

  const snap = await db
    .collection('users')
    .doc(uid)
    .collection('chat_sessions')
    .orderBy('updatedAt', 'desc')
    .get();

  const sessions = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
  res.json(sessions);
});

/**
 * DELETE /api/chat/sessions/:id
 * Deletes a chat session and all its messages.
 */
router.delete('/sessions/:id', async (req, res) => {
  const uid = req.user.uid;
  const sessionId = req.params.id;

  const sessionRef = db
    .collection('users')
    .doc(uid)
    .collection('chat_sessions')
    .doc(sessionId);

  // Delete all messages in the sub-collection first
  const messagesSnap = await sessionRef.collection('messages').get();
  const batch = db.batch();
  messagesSnap.docs.forEach((d) => batch.delete(d.ref));
  batch.delete(sessionRef);
  await batch.commit();

  res.json({ success: true });
});

module.exports = router;
