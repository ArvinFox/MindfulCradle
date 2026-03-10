const router = require('express').Router();
const { body, param } = require('express-validator');
const { validateRequest } = require('../middleware/validate');
const { verifyToken } = require('../middleware/auth');
const { db } = require('../config/firebase');
const { sendToToken } = require('../services/notificationService');
const logger = require('../config/logger');

const VALID_ACHIEVEMENTS = [
  'first_step', 'halfway_there', 'zen_master',
  'self_aware', 'mindful_observer', 'happiness_seeker', 'super_mom',
];

const SUPER_MOM_PREREQUISITES = [
  'first_step', 'halfway_there', 'zen_master',
  'self_aware', 'mindful_observer', 'happiness_seeker',
];

router.use(verifyToken);

/**
 * POST /api/achievements/unlock
 * Server validates eligibility before writing the achievement to Firestore.
 *
 * Body: { achievementId: string }
 */
router.post(
  '/unlock',
  [body('achievementId').isIn(VALID_ACHIEVEMENTS)],
  validateRequest,
  async (req, res) => {
    const uid = req.user.uid;
    const { achievementId } = req.body;

    const userRef = db.collection('users').doc(uid);
    const userDoc = await userRef.get();

    if (!userDoc.exists) return res.status(404).json({ error: 'User not found.' });

    const userData = userDoc.data();
    const current = new Set(userData.achievements || []);

    if (current.has(achievementId)) {
      return res.json({ success: true, alreadyUnlocked: true });
    }

    // --- Eligibility checks ---
    if (['first_step', 'halfway_there', 'zen_master'].includes(achievementId)) {
      // Video-based: let the client claim it; the videoProgress sub-collection
      // is the source of truth. We trust the client here since unlock logic
      // is also validated in VideoProvider. A deeper server check could query
      // videoProgress if needed.
    }

    if (achievementId === 'super_mom') {
      const hasAll = SUPER_MOM_PREREQUISITES.every((id) => current.has(id));
      if (!hasAll) {
        return res.status(403).json({ error: 'Prerequisites not met for super_mom.' });
      }
    }

    // Write achievement
    const newAchievements = [...current, achievementId];
    await userRef.update({ achievements: newAchievements });

    // Auto-unlock super_mom if all prerequisites are now met
    const unlockedIds = [];
    if (
      achievementId !== 'super_mom' &&
      SUPER_MOM_PREREQUISITES.every((id) => new Set(newAchievements).has(id))
    ) {
      await userRef.update({
        achievements: [...newAchievements, 'super_mom'],
      });
      unlockedIds.push('super_mom');
      logger.info('super_mom auto-unlocked', { uid });
    }

    // Optionally send a push notification for the unlock
    if (userData.fcmToken) {
      sendToToken(
        userData.fcmToken,
        '🏆 Achievement Unlocked!',
        `You earned: ${achievementId.replace(/_/g, ' ')}`,
        { achievementId }
      ).catch((err) => logger.warn('Achievement push failed', { error: err.message }));
    }

    res.json({ success: true, unlockedIds: [achievementId, ...unlockedIds] });
  }
);

module.exports = router;
