const { db, messaging } = require("../config/firebase");
const logger = require("../config/logger");

/**
 * Sends a data/notification message to a specific FCM token.
 */
async function sendToToken(token, title, body, data = {}) {
  const message = {
    token,
    notification: { title, body },
    data,
    android: {
      priority: "high",
      notification: { channelId: "mindful_cradle_reminders" },
    },
    apns: {
      payload: { aps: { sound: "default", badge: 1 } },
    },
  };

  const result = await messaging.send(message);
  logger.debug("FCM message sent", { messageId: result, token });
  return result;
}

/**
 * Sends to a Firebase topic (e.g. 'all_users', 'en_users', 'si_users').
 */
async function sendToTopic(topic, title, body, data = {}) {
  const message = {
    topic,
    notification: { title, body },
    data,
    android: {
      priority: "high",
      notification: { channelId: "mindful_cradle_reminders" },
    },
    apns: {
      payload: { aps: { sound: "default", badge: 1 } },
    },
  };

  const result = await messaging.send(message);
  logger.info("FCM topic message sent", { topic, messageId: result });
  return result;
}

/**
 * Sends a multicast message to up to 500 tokens at once.
 * Returns { successCount, failureCount, failedTokens }.
 */
async function sendMulticast(tokens, title, body, data = {}) {
  if (!tokens.length)
    return { successCount: 0, failureCount: 0, failedTokens: [] };

  // FCM multicast limit is 500 tokens per call
  const chunks = [];
  for (let i = 0; i < tokens.length; i += 500) {
    chunks.push(tokens.slice(i, i + 500));
  }

  let successCount = 0;
  let failureCount = 0;
  const failedTokens = [];

  for (const chunk of chunks) {
    const message = {
      tokens: chunk,
      notification: { title, body },
      data,
      android: {
        priority: "high",
        notification: { channelId: "mindful_cradle_reminders" },
      },
      apns: {
        payload: { aps: { sound: "default", badge: 1 } },
      },
    };

    const result = await messaging.sendEachForMulticast(message);
    successCount += result.successCount;
    failureCount += result.failureCount;

    result.responses.forEach((resp, idx) => {
      if (!resp.success) {
        failedTokens.push(chunk[idx]);
        logger.warn("FCM delivery failed", {
          token: chunk[idx],
          error: resp.error?.message,
        });
      }
    });
  }

  return { successCount, failureCount, failedTokens };
}

/**
 * Fetches all FCM tokens from users who have them stored.
 * Users should save their FCM token to users/{uid}.fcmToken on login.
 */
async function getAllActiveTokens() {
  const snapshot = await db
    .collection("users")
    .where("fcmToken", "!=", null)
    .get();
  return snapshot.docs.map((doc) => doc.data().fcmToken).filter(Boolean);
}

module.exports = {
  sendToToken,
  sendToTopic,
  sendMulticast,
  getAllActiveTokens,
};
