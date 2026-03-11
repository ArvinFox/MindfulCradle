require("dotenv").config();

const express = require("express");
const helmet = require("helmet");
const cors = require("cors");
const morgan = require("morgan");

const { apiLimiter } = require("./middleware/rateLimiter");
const { verifyToken, requireAdmin } = require("./middleware/auth");
const logger = require("./config/logger");

// Route handlers
const chatRoutes = require("./routes/chat");
const userRoutes = require("./routes/user");
const notificationRoutes = require("./routes/notifications");
const achievementRoutes = require("./routes/achievements");

// Admin route handlers
const analyticsAdminRoutes = require("./routes/admin/analytics");
const questionnairesAdminRoutes = require("./routes/admin/questionnaires");
const videosAdminRoutes = require("./routes/admin/videos");
const notificationsAdminRoutes = require("./routes/admin/notifications");

const app = express();

// ── Security & Parsing ──────────────────────────────────────────────────────
app.use(helmet());

const allowedOrigins = (process.env.ALLOWED_ORIGINS || "")
  .split(",")
  .map((o) => o.trim())
  .filter(Boolean);

app.use(
  cors({
    origin: allowedOrigins.length ? allowedOrigins : false,
    methods: ["GET", "POST", "PUT", "DELETE"],
    allowedHeaders: ["Content-Type", "Authorization"],
  }),
);

app.use(express.json({ limit: "50kb" })); // Prevents large payload attacks
app.use(
  morgan("combined", { stream: { write: (msg) => logger.info(msg.trim()) } }),
);

// ── Global Rate Limiting ─────────────────────────────────────────────────────
app.use("/api/", apiLimiter);

// ── Health Check ─────────────────────────────────────────────────────────────
app.get("/health", (req, res) =>
  res.json({ status: "ok", uptime: process.uptime() }),
);

// ── Public Routes ─────────────────────────────────────────────────────────────
// (none — all routes require authentication)

// ── Authenticated User Routes ─────────────────────────────────────────────────
app.use("/api/chat", chatRoutes);
app.use("/api/user", userRoutes);
app.use("/api/notifications", notificationRoutes);
app.use("/api/achievements", achievementRoutes);

// ── Admin Routes (requires valid token + admin UID) ───────────────────────────
app.use("/api/admin", verifyToken, requireAdmin);
app.use("/api/admin/analytics", analyticsAdminRoutes);
app.use("/api/admin/questionnaires", questionnairesAdminRoutes);
app.use("/api/admin/videos", videosAdminRoutes);
app.use("/api/admin/notifications", notificationsAdminRoutes);

// ── 404 Handler ───────────────────────────────────────────────────────────────
app.use((req, res) => {
  res.status(404).json({ error: "Route not found." });
});

// ── Global Error Handler ──────────────────────────────────────────────────────
// eslint-disable-next-line no-unused-vars
app.use((err, req, res, next) => {
  logger.error("Unhandled error", { error: err.message, stack: err.stack });
  res.status(500).json({ error: "Internal server error." });
});

module.exports = app;
