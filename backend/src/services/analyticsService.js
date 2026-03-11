const { db } = require("../config/firebase");

/**
 * Returns aggregate analytics data for the admin dashboard.
 * All queries use the Admin SDK so there are no Firestore security rule restrictions.
 */

async function getUserStats() {
  const usersSnap = await db.collection("users").get();
  const users = usersSnap.docs.map((d) => d.data());

  const total = users.length;
  const registered = users.filter((u) => u.isUserRegistrationComplete).length;
  const totalSessionSeconds = users.reduce(
    (sum, u) => sum + (u.totalSessionTime || 0),
    0,
  );
  const avgSessionMinutes =
    total > 0 ? Math.round(totalSessionSeconds / total / 60) : 0;

  const byResidence = {};
  users.forEach((u) => {
    if (u.residence)
      byResidence[u.residence] = (byResidence[u.residence] || 0) + 1;
  });

  const byPregnancyMonth = {};
  users.forEach((u) => {
    if (u.pregnancyMonth) {
      byPregnancyMonth[u.pregnancyMonth] =
        (byPregnancyMonth[u.pregnancyMonth] || 0) + 1;
    }
  });

  return {
    total,
    registered,
    avgSessionMinutes,
    byResidence,
    byPregnancyMonth,
  };
}

async function getQuestionnaireStats() {
  const tools = ["dass21", "maas", "pws18"];
  const result = {};

  for (const tool of tools) {
    const collectionId = `${tool}_responses`;
    // Collectiongroup query across all users
    const snap = await db.collectionGroup(collectionId).get();
    const attempts = snap.docs.map((d) => d.data());

    result[tool] = {
      totalAttempts: attempts.length,
    };

    if (tool === "dass21" && attempts.length > 0) {
      const avg = (field) =>
        Math.round(
          attempts.reduce((s, a) => s + (a.scores?.[field] || 0), 0) /
            attempts.length,
        );
      result[tool].avgScores = {
        depression: avg("depression"),
        anxiety: avg("anxiety"),
        stress: avg("stress"),
      };
    }

    if (tool === "maas" && attempts.length > 0) {
      const avgScore =
        attempts.reduce((s, a) => s + (a.maasScore || 0), 0) / attempts.length;
      result[tool].avgScore = Math.round(avgScore * 10) / 10;
    }
  }

  return result;
}

async function getVideoStats() {
  const videosSnap = await db.collection("videos").get();
  const progressSnap = await db.collectionGroup("videoProgress").get();

  const watchMap = {};
  progressSnap.docs.forEach((d) => {
    const { watchedSeconds } = d.data();
    const videoId = d.id;
    if (!watchMap[videoId]) watchMap[videoId] = { totalSeconds: 0, viewers: 0 };
    watchMap[videoId].totalSeconds += watchedSeconds || 0;
    watchMap[videoId].viewers += 1;
  });

  const videos = videosSnap.docs.map((d) => {
    const data = d.data();
    const stats = watchMap[d.id] || { totalSeconds: 0, viewers: 0 };
    return {
      id: d.id,
      title: data.title,
      sessionNumber: data.sessionNumber,
      viewers: stats.viewers,
      avgWatchSeconds:
        stats.viewers > 0 ? Math.round(stats.totalSeconds / stats.viewers) : 0,
    };
  });

  return videos.sort((a, b) => a.sessionNumber - b.sessionNumber);
}

async function getAchievementStats() {
  const usersSnap = await db.collection("users").get();
  const counts = {};

  usersSnap.docs.forEach((d) => {
    const achievements = d.data().achievements || [];
    achievements.forEach((id) => {
      counts[id] = (counts[id] || 0) + 1;
    });
  });

  return counts;
}

module.exports = {
  getUserStats,
  getQuestionnaireStats,
  getVideoStats,
  getAchievementStats,
};
