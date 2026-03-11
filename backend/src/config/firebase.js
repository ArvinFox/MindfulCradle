const admin = require("firebase-admin");

// Initialize Firebase Admin SDK once and export the instances.
// Credentials are loaded from environment variables — the private key
// newline escape (\n) must be unescaped when read from a .env file.
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert({
      projectId: process.env.FIREBASE_PROJECT_ID,
      clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, "\n"),
    }),
  });
}

const db = admin.firestore();
const auth = admin.auth();
const messaging = admin.messaging();

module.exports = { admin, db, auth, messaging };
