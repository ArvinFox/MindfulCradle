require('dotenv').config();

const app = require('./src/app');
const logger = require('./src/config/logger');
const { startScheduler } = require('./src/jobs/notificationScheduler');

const PORT = process.env.PORT || 3000;

// Validate required environment variables before starting
const REQUIRED_ENV = ['FIREBASE_PROJECT_ID', 'FIREBASE_CLIENT_EMAIL', 'FIREBASE_PRIVATE_KEY', 'GEMINI_API_KEY'];
const missing = REQUIRED_ENV.filter((key) => !process.env[key]);
if (missing.length) {
  logger.error(`Missing required environment variables: ${missing.join(', ')}`);
  process.exit(1);
}

const server = app.listen(PORT, () => {
  logger.info(`MindfulCradle backend running on port ${PORT} [${process.env.NODE_ENV || 'development'}]`);

  // Start cron jobs after server is ready
  startScheduler();
});

// Graceful shutdown
process.on('SIGTERM', () => {
  logger.info('SIGTERM received — shutting down gracefully');
  server.close(() => {
    logger.info('Server closed');
    process.exit(0);
  });
});

process.on('unhandledRejection', (reason) => {
  logger.error('Unhandled promise rejection', { reason });
});
