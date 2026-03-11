const router = require("express").Router();
const {
  getUserStats,
  getQuestionnaireStats,
  getVideoStats,
  getAchievementStats,
} = require("../../services/analyticsService");
const logger = require("../../config/logger");

/**
 * GET /api/admin/analytics/users
 */
router.get("/users", async (req, res) => {
  const stats = await getUserStats();
  res.json(stats);
});

/**
 * GET /api/admin/analytics/questionnaires
 */
router.get("/questionnaires", async (req, res) => {
  const stats = await getQuestionnaireStats();
  res.json(stats);
});

/**
 * GET /api/admin/analytics/videos
 */
router.get("/videos", async (req, res) => {
  const stats = await getVideoStats();
  res.json(stats);
});

/**
 * GET /api/admin/analytics/achievements
 */
router.get("/achievements", async (req, res) => {
  const stats = await getAchievementStats();
  res.json(stats);
});

/**
 * GET /api/admin/analytics/summary
 * All stats in one call.
 */
router.get("/summary", async (req, res) => {
  const [users, questionnaires, videos, achievements] = await Promise.all([
    getUserStats(),
    getQuestionnaireStats(),
    getVideoStats(),
    getAchievementStats(),
  ]);
  res.json({ users, questionnaires, videos, achievements });
});

module.exports = router;
