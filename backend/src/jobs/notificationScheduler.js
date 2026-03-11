const cron = require("node-cron");
const {
  sendMulticast,
  getAllActiveTokens,
} = require("../services/notificationService");
const logger = require("../config/logger");

/**
 * Server-side global push notification schedule.
 *
 * These are BROADCAST notifications (sent to all users).
 * They complement the per-device local notifications scheduled in the Flutter app.
 * Use these for global announcements, weekly wellness summaries, new content alerts, etc.
 *
 * All times are based on the server's timezone — set TZ env var accordingly.
 * Example: TZ=Asia/Colombo  (UTC+5:30 for Sri Lanka)
 *
 * Cron syntax: second(optional) minute hour day-of-month month day-of-week
 */

function startScheduler() {
  // Every Monday at 8:00 AM — Weekly wellness reminder
  cron.schedule("0 8 * * 1", async () => {
    logger.info("Running weekly wellness notification job");
    try {
      const tokens = await getAllActiveTokens();
      await sendMulticast(
        tokens,
        "🌸 Weekly Wellness Check",
        "Start your week with a mindfulness session. Your baby feels what you feel!",
        { type: "weekly_wellness" },
      );
    } catch (err) {
      logger.error("Weekly wellness notification failed", {
        error: err.message,
      });
    }
  });

  // Every day at 9:00 AM — Morning meditation nudge
  cron.schedule("0 9 * * *", async () => {
    logger.info("Running morning meditation notification job");
    try {
      const tokens = await getAllActiveTokens();
      await sendMulticast(
        tokens,
        "🧘 Good Morning!",
        "Take 10 minutes for your mindfulness session today.",
        { type: "morning_meditation" },
      );
    } catch (err) {
      logger.error("Morning meditation notification failed", {
        error: err.message,
      });
    }
  });

  // First day of each month at 10:00 AM — Questionnaire reminder
  cron.schedule("0 10 1 * *", async () => {
    logger.info("Running monthly questionnaire notification job");
    try {
      const tokens = await getAllActiveTokens();
      await sendMulticast(
        tokens,
        "📋 Monthly Check-in Available",
        "Your monthly wellness questionnaires are now available. Track your progress!",
        { type: "questionnaire_unlock", screen: "questionnaires" },
      );
    } catch (err) {
      logger.error("Monthly questionnaire notification failed", {
        error: err.message,
      });
    }
  });

  logger.info("Notification scheduler started.");
}

module.exports = { startScheduler };
