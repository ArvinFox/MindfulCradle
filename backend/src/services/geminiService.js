const fetch = require("node-fetch");
const logger = require("../config/logger");

const GEMINI_API_BASE =
  "https://generativelanguage.googleapis.com/v1beta/models";

/**
 * Loads the pregnancy FAQ knowledge base.
 * In production this could be read from Firestore or a file cache,
 * but we keep the same JSON structure used by the Flutter app.
 */
const FAQ_PATH = require("path").join(
  __dirname,
  "../../faq/pregnancy_faq.json",
);
let faqCache = null;

function loadFaq() {
  if (faqCache) return faqCache;
  try {
    faqCache = require(FAQ_PATH);
  } catch {
    faqCache = [];
    logger.warn(
      "pregnancy_faq.json not found — chatbot will run without FAQ context.",
    );
  }
  return faqCache;
}

/**
 * Builds the RAG system prompt identical to the Flutter RagService logic.
 */
function buildPrompt(userMessage, history = [], languageHint = "en") {
  const faq = loadFaq();

  const langInstruction =
    languageHint === "si"
      ? "Please respond in Sinhala (සිංහල) language."
      : "Please respond in English.";

  const faqContext = faq
    .map(
      (item) =>
        `Q: ${item.question}\nA: ${item.answer}\nCategory: ${item.category}`,
    )
    .join("\n\n");

  const historyText = history
    .slice(-6) // last 3 exchanges to keep tokens reasonable
    .map((m) => `${m.role === "user" ? "User" : "Assistant"}: ${m.text}`)
    .join("\n");

  return `You are a compassionate pregnancy wellness assistant for MindfulCradle, a prenatal mental health app.
You help expectant mothers with questions about pregnancy, mental health, mindfulness, and wellbeing.
${langInstruction}
Always be warm, supportive, and evidence-based. Never give specific medical diagnoses.

=== KNOWLEDGE BASE ===
${faqContext}

=== CONVERSATION HISTORY ===
${historyText}

=== USER MESSAGE ===
${userMessage}`;
}

/**
 * One-shot Gemini response. Returns the text string.
 */
async function generateAnswer(userMessage, history = [], languageHint = "en") {
  const apiKey = process.env.GEMINI_API_KEY;
  const model = process.env.GEMINI_MODEL || "gemini-3-flash-preview";

  const prompt = buildPrompt(userMessage, history, languageHint);

  const response = await fetch(
    `${GEMINI_API_BASE}/${model}:generateContent?key=${apiKey}`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        contents: [{ role: "user", parts: [{ text: prompt }] }],
      }),
    },
  );

  if (!response.ok) {
    const errText = await response.text();
    logger.error("Gemini API error", {
      status: response.status,
      body: errText,
    });
    throw new Error(`Gemini API returned ${response.status}`);
  }

  const data = await response.json();
  return data.candidates?.[0]?.content?.parts?.[0]?.text ?? "";
}

/**
 * Streaming Gemini response via SSE.
 * Pipes SSE chunks directly to the Express response object.
 * The caller must set res headers before calling this function.
 */
async function streamAnswer(
  userMessage,
  history = [],
  languageHint = "en",
  res,
) {
  const apiKey = process.env.GEMINI_API_KEY;
  const model = process.env.GEMINI_MODEL || "gemini-3-flash-preview";

  const prompt = buildPrompt(userMessage, history, languageHint);

  const response = await fetch(
    `${GEMINI_API_BASE}/${model}:streamGenerateContent?alt=sse&key=${apiKey}`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        contents: [{ role: "user", parts: [{ text: prompt }] }],
      }),
    },
  );

  if (!response.ok) {
    const errText = await response.text();
    logger.error("Gemini streaming API error", {
      status: response.status,
      body: errText,
    });
    res.write(`data: ${JSON.stringify({ error: "AI service error" })}\n\n`);
    res.end();
    return;
  }

  // Pipe SSE events through to the client
  response.body.on("data", (chunk) => {
    res.write(chunk);
  });

  response.body.on("end", () => {
    res.end();
  });

  response.body.on("error", (err) => {
    logger.error("Gemini stream error", { error: err.message });
    res.end();
  });
}

module.exports = { generateAnswer, streamAnswer };
