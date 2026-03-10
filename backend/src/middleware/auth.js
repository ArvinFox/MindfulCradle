const { auth } = require('../config/firebase');
const logger = require('../config/logger');

/**
 * Verifies the Firebase ID token sent in the Authorization header.
 * Attaches the decoded token as req.user on success.
 *
 * The Flutter app should send:
 *   Authorization: Bearer <id_token>
 */
async function verifyToken(req, res, next) {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Missing or malformed Authorization header.' });
  }

  const idToken = authHeader.split('Bearer ')[1];

  try {
    const decoded = await auth.verifyIdToken(idToken);
    req.user = decoded; // { uid, email, ... }
    next();
  } catch (err) {
    logger.warn('Token verification failed', { error: err.message });
    return res.status(401).json({ error: 'Invalid or expired token.' });
  }
}

/**
 * Middleware to restrict routes to admin users only.
 * Must be used AFTER verifyToken.
 * Admin UIDs are listed in the ADMIN_UIDS environment variable.
 */
function requireAdmin(req, res, next) {
  const adminUids = (process.env.ADMIN_UIDS || '').split(',').map((u) => u.trim());

  if (!adminUids.includes(req.user?.uid)) {
    return res.status(403).json({ error: 'Forbidden: admin access required.' });
  }

  next();
}

module.exports = { verifyToken, requireAdmin };
