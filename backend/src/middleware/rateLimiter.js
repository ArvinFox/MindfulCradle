const rateLimit = require("express-rate-limit");

/**
 * General API rate limiter — 100 requests per 15 minutes per IP.
 */
const apiLimiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000,
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: "Too many requests, please try again later." },
});

/**
 * Stricter limiter for the Gemini chat endpoints — 30 requests per 15 minutes per IP.
 * Prevents API key abuse even if the token is valid.
 */
const chatLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: parseInt(process.env.CHAT_RATE_LIMIT_MAX) || 30,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    error:
      "Chat rate limit exceeded. Please wait before sending more messages.",
  },
});

module.exports = { apiLimiter, chatLimiter };
