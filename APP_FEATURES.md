# Mindful Cradle — App Features

A Flutter-based maternal mental health companion app targeting pregnant and postpartum women in Sri Lanka. Supports English and Sinhala throughout.

---

## 1. Authentication & Onboarding

### First-Launch Onboarding

- 4-slide illustrated introduction shown once on first install
- Covers app purpose, assessments, AI companion, and achievements
- Stored in SharedPreferences (`onboarding_complete`)

### Sign Up / Login

- Email & password registration via Firebase Auth
- Google Sign-In integration
- Forgot password flow (email reset)
- Language selector (English / Sinhala) on both login and sign-up screens

### User Registration Form

- Multi-step form collected after account creation
- Step 1: Age, place of residence
- Step 2: Pregnancy month, first-time mother, employment status, obstetric complications, psychological support history, distressing life events, mindfulness experience
- Language selector available on the registration page itself
- Data saved to Firestore `users/{uid}`

### Splash Screen

- Animated gradient logo splash with 4-second minimum display
- Pre-loads auth state so routing is instant after splash

---

## 2. Main Navigation

### Bottom Navigation Bar (MainScreen)

- Floating pill-shaped custom nav bar with 5 tabs
- **Tab 0 — Home**, **Tab 1 — Questionnaires**, **Tab 2 — Chat**, **Tab 3 — Achievements**, **Tab 4 — Profile**
- `extendBody: true` — content runs behind transparent nav bar
- Tab can be pre-selected via `initialTab` constructor parameter (used by wellness navigation)
- Double-back-press to exit guard

### Connectivity Banner

- Persistent red banner appears at the top of any screen when offline
- Bilingual message (English / Sinhala)
- Disappears automatically when connection is restored

---

## 3. Home Page

### Hero Section

- Personalised greeting with user's first name
- Daily motivational subtitle (changes based on time of day)

### Mood & Journal Quick-Access Cards

- One-tap shortcuts to log today's mood or write a journal entry
- Shows today's mood emoji if already checked in

### Mindfulness / Meditation Video Grid

- Curated pregnancy-safe meditation and breathing exercise videos
- Compact / expanded tile toggle
- Video completion tracked per user in Firestore
- Progress shown on each tile (completed badge)

### Warm Mood Prompt

- Gentle bottom-sheet nudge fires ~3 seconds after home loads if the user hasn't logged mood today
- Only shown after tutorial is complete; skipped once after registration
- Personalised with first name

### Smart Promotion Dialogs

- Context-aware nudge shown 15–30 s after home loads (once per session)
- Four types: Journal, Mood check-in, Meditation, Assessment
- Promotion type chosen based on what the user hasn't done recently
- Respects tutorial completion and daily limits

---

## 4. Mood Tracker

### Daily Mood Check-In

- 5-point emoji scale: Very Sad 😢 → Very Happy 😄
- Optional free-text note
- Enforces one check-in per day (shows info snackbar if already logged)
- Accessible from Home quick-access card, warm prompt, or Mood Tracker screen

### Mood History & Analytics

- Weekly bar chart showing mood index per day
- Streak / history calendar view
- Last entry summary card

### Crisis & Distress Detection on Save

- **Synchronous keyword check first** (guaranteed baseline, zero latency)
  - Checks both English and Sinhala keyword lists regardless of app language
  - Crisis: suicidal ideation, self-harm phrases
  - Distress: hopelessness, loneliness, helplessness keywords
  - Mood index ≤ 1 (Sad or Very Sad) auto-triggers distress level
- **AI detection runs concurrently** with Firestore save (Gemini 2.0 Flash Lite, `maxOutputTokens: 10`)
  - Silently falls back to keyword result on any API error, timeout, or quota issue
  - Upgrades level if AI detects something more severe than keywords

---

## 5. Journal

### Write Entry

- Title + freeform content fields
- Saved to Firestore with timestamp, language tag, and sentiment analysis

### Journal List

- Chronological list of all entries
- Sentiment emoji and tag chips on each card

### Journal Detail

- Full entry view with sentiment score, mood tags, semantic categories

### Sentiment Analysis

- Rule-based `JournalAnalysis` utility scores every entry on save
- Positive/Negative/Neutral classification with score (−1.0 to +1.0)
- Semantic tags: pregnancy, emotions, health, sleep, work, family, etc.

### Crisis & Distress Detection on Save

- Same three-layer detection as mood (keyword → AI → fallback)
- Triggered immediately on save before navigation
- Save and AI detection run in parallel; a Firestore error never kills detection

---

## 6. AI Companion Chat (RAG Chatbot)

### Retrieval-Augmented Generation

- Backed by Gemini (streaming SSE) with a curated `pregnancy_faq.json` knowledge base
- Knowledge base injected into every prompt for grounded, accurate answers
- Last 5 messages of conversation history included for context

### Real-Time Streaming

- Bot responses stream token-by-token for a live typing feel
- Thinking indicator shown while waiting for first token
- Smooth scroll-to-bottom as response builds

### Chat Session Management

- Each conversation is a named session stored in Firestore (`users/{uid}/chatSessions`)
- Session auto-titled from first user message
- History pane (slide-in panel) lists all past sessions with timestamps
- Load any previous session, or delete it
- "Start New Chat" button with confirmation dialog

### Crisis Detection in Chat

- Keyword-based detection on every user message sent
- If crisis content detected: `crisisExtra` system prompt injected into Gemini request
  - Instructs AI to respond with deep empathy, validate feelings, and mention Sri Lanka-specific helplines only (National Mental Health Helpline 1926, CCC 1333, Sumithrayo 0112682535)
- Crisis card appended below bot response with helpline buttons

### Wellness-Triggered Greeting

- When user navigates to Chat via the Wellness Support Dialog (from journal/mood crisis detection):
  - A hidden system context is written to SharedPreferences before navigation
  - On chat init, context is read and cleared (one-shot, cannot replay)
  - AI sends a warm, personalised opening greeting without the user typing anything
  - Crisis trigger → empathetic, helpline-aware greeting
  - Distress trigger → gentle check-in, uplifting greeting
  - Fallback hardcoded message if API fails
  - Typing indicator shown immediately (before first token arrives) — no blank screen

### Language Support

- Language hint injected into every Gemini prompt
- Responds in English or Sinhala to match app language

### Bilingual UI

- All buttons, placeholders, error messages in English and Sinhala

---

## 7. Assessments (Questionnaires)

### DASS-21 (Depression Anxiety Stress Scale)

- 21-item validated clinical questionnaire
- Scores three sub-scales: Depression, Anxiety, Stress
- Severity classification: Normal / Mild / Moderate / Severe / Extremely Severe
- Results stored per attempt in Firestore
- Attempt history with expandable cards showing per-subscale breakdown
- Contextual hints per question (colour-coded guidance)
- Unlocks **Self Aware** achievement on first completion

### MAAS (Mindful Attention Awareness Scale)

- 15-item mindfulness assessment
- Single overall score with classification
- Attempt history
- Unlocks **Mindful Observer** achievement on first completion

### PWS-18 (Prenatal Wellbeing Scale)

- 18-item prenatal psychological wellbeing scale
- Score and classification
- Attempt history
- Unlocks **Happiness Seeker** achievement on first completion

### Common Questionnaire Features

- Offline guard: shows connectivity warning if no internet
- Rate limiting: prevents re-attempting too soon
- Animated intro screen before each questionnaire
- Marquee scrolling title for long questionnaire names
- Result tiles with colour-coded severity indicators

---

## 8. Achievements

### 13 Unlockable Badges

| ID                 | Title            | Trigger                                 |
| ------------------ | ---------------- | --------------------------------------- |
| `first_step`       | First Step       | Watched first meditation video          |
| `halfway_there`    | Halfway There    | Completed 4 meditation videos           |
| `zen_master`       | Zen Mom          | Completed all 8 meditation videos       |
| `self_aware`       | Self Aware       | First DASS-21 completion                |
| `mindful_observer` | Mindful Observer | First MAAS completion                   |
| `happiness_seeker` | Happiness Seeker | First PWS-18 completion                 |
| `super_mom`        | Super Mom        | Completed all videos + all assessments  |
| `first_journal`    | Dear Diary       | First journal entry written             |
| `journal_writer`   | Storyteller      | 5 journal entries written               |
| `mood_check_in`    | Feeling Aware    | First mood check-in logged              |
| `mood_tracker`     | Consistent Soul  | 5 mood check-ins logged                 |
| `chat_companion`   | Chat Companion   | First AI companion chat session started |

### Achievement UI

- Progress header showing unlocked count / total
- Grid of achievement cards (locked = greyed, unlocked = full colour)
- Tap any card for detail bottom-sheet with gradient banner
- Confetti / celebration animation on unlock (via `showPendingAchievements`)
- Achievements persisted in Firestore `users/{uid}.achievements`

---

## 9. Crisis Safety Layer

### Multi-Layer Detection

- **Layer 1 — Keywords (synchronous):** Checks both English and Sinhala crisis/distress keyword lists simultaneously, regardless of current app language. Includes 30+ Sinhala crisis phrases covering all common conjugations.
- **Layer 2 — AI classification (async, parallel):** Gemini 2.0 Flash Lite one-shot call. `maxOutputTokens: 10`, `temperature: 0.1`. Returns `crisis / distress / none`. 5-second timeout.
- **Layer 3 — Sentiment score:** If journal sentiment score < −0.5 → distress.
- **Fallback guarantee:** If API fails for any reason (network, quota, timeout, bad JSON), keyword result is used. Detection never silently fails.

### Wellness Support Dialog

**Crisis Sheet** (non-dismissible)

- "You're Not Alone 💚" heading
- Three Sri Lanka helpline buttons with one-tap calling:
  - National Mental Health Helpline: **1926**
  - CCCline: **1333**
  - Sumithrayo: **0112 696 666**
- "Chat with Companion" button

**Distress Sheet** (dismissible)

- "We're Here for You 🌸" heading
- Three action buttons:
  - 🧘 **Mindfulness** → MainScreen Home tab (meditation sessions)
  - 📋 **Take Assessment** → MainScreen Questionnaires tab
  - 💬 **Chat with Companion** → MainScreen Chat tab

### Navigation After Crisis Action

- All navigation uses `pushAndRemoveUntil` to `MainScreen(initialTab: N)` — clears the stack and opens the correct tab with a full navigation bar
- Before navigating to Chat, writes `wellness_trigger` + `wellness_trigger_lang` to SharedPreferences so the chat sends a personalised AI greeting

---

## 10. Profile & Settings

### Profile Page

- Display name, email, profile photo
- Upload profile photo from gallery (Cloudinary CDN, 512×512, 85% quality)
- Language switcher (English ↔ Sinhala) — persists across sessions
- Links to notification settings and privacy/account management

### Notification Settings

- Permission request flow with graceful degradation
- Five configurable scheduled reminder types:
  - Meditation reminder
  - Companion chat reminder
  - Wellness tip
  - Questionnaire reminder
  - Hydration reminder
- Firebase Cloud Messaging (FCM) for push notifications
- flutter_local_notifications for scheduled local reminders
- Timezone-aware scheduling using IANA timezone (`Asia/Colombo`)

### GDPR Account Management

- **Export My Data:** Exports all user data (profile, journal, mood, assessments) as a CSV file saved to device Downloads
- **Delete Account:** Permanently deletes Firestore data and Firebase Auth account with confirmation dialog
- Bilingual UI throughout

---

## 11. In-App Tutorial (Coach Mark)

### First-Time Tutorial

- Triggered automatically after login if `tutorial_done` is false in Firestore / SharedPreferences
- 8-step coach-mark overlay with spotlight on each UI element:
  1. Welcome to Mindful Cradle
  2. Home tab navigation
  3. Home page hero card
  4. Notification bell icon (GlobalKey spotlight)
  5. Questionnaires tab
  6. Chat tab
  7. Achievements tab
  8. Profile tab (mentions photo and language switch)
- Each step spotlights the actual nav bar button via GlobalKey
- Tutorial state synced to Firestore `users/{uid}.isTutorialDone`
- Can be re-triggered from profile (for testing / accessibility)

### App Introduction Tutorial Screen

- Separate full-screen swipeable tutorial (`AppTutorialScreen`)
- Shown between login and main app on first use
- Animated gradient cards with feature overview chips

---

## 12. Localisation

- Full bilingual support: **English (en)** and **Sinhala (si)**
- Language files in `languages/` directory:
  - `auth.json`, `common.json`, `chat.json`, `home.json`, `profile.json`
  - `questionnaires.json`, `notifications.json`, `validators.json`
  - `achievements.json`, `video_hints.json`
  - Questionnaire-specific: `dass21_en.json`, `dass21_si.json`, `maas_en.json`, `maas_si.json`, `pws18_en.json`, `pws18_si.json`
- `LanguageProvider` persists chosen language to SharedPreferences
- `context.t` extension for inline translations throughout the app

---

## 13. Technical Architecture

| Concern            | Solution                                                |
| ------------------ | ------------------------------------------------------- |
| State management   | Provider pattern                                        |
| Backend            | Firebase (Auth, Firestore)                              |
| AI                 | Google Gemini 2.0 Flash Lite (streaming SSE via `http`) |
| RAG knowledge base | Local JSON (`assets/data/pregnancy_faq.json`)           |
| Image hosting      | Cloudinary CDN                                          |
| Push notifications | Firebase Cloud Messaging + flutter_local_notifications  |
| Offline detection  | `connectivity_plus` → `ConnectivityProvider`            |
| Secure storage     | `flutter_secure_storage`                                |
| Video playback     | In-app WebView (`flutter_inappwebview`)                 |
| Navigation         | Named routes + `MaterialPageRoute`                      |
| Fonts              | Google Fonts — Poppins (headings), Roboto (body)        |
| Design system      | Material 3, custom `AppColors`, hero gradient           |
| Platform           | Android (primary), iOS supported                        |
