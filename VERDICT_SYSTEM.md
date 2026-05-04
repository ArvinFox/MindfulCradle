# Final Verdict System — Technical Reference

This document explains how the analytical final verdict is computed for each questionnaire in MindfulCradle. All logic lives in `lib/services/questionnaire_verdict_service.dart`.

---

## Overview

The verdict system activates **after all 3 attempts** of a questionnaire are complete. It analyses the score trajectory across the three attempts and produces a `QuestionnaireVerdict` object containing:

| Field | Description |
|---|---|
| `trendLabel` / `trendLabelSi` | Short label (e.g. "Strong Improvement") in English / Sinhala |
| `emoji` | Visual indicator emoji |
| `summary` / `summarySi` | Multi-sentence narrative in English / Sinhala |
| `subscaleInsights` / `subscaleInsightsSi` | Per-subscale/score breakdown map |
| `trendCode` | Machine-readable code: `"improving"`, `"stable"`, `"fluctuating"`, `"declining"` |
| `computedAt` | Timestamp (server-side via Firestore) |

The verdict is saved to Firestore at `users/{userId}/{subcollection}/final_verdict` and loaded from there on subsequent visits (no recomputation unless absent).

---

## DASS-21 — Feelings Checker

**Service class:** `DASS21VerdictEngine`  
**Scoring range:** 0–42 per subscale (7 items × max 3, then × 2)  
**Direction:** **Lower = better** (more distress = higher score)

### Subscales

| Subscale | Normal | Mild | Moderate | Severe | Extremely Severe |
|---|---|---|---|---|---|
| Depression | 0–9 | 10–13 | 14–20 | 21–27 | 28–42 |
| Anxiety | 0–7 | 8–9 | 10–14 | 15–19 | 20–42 |
| Stress | 0–14 | 15–18 | 19–25 | 26–33 | 34–42 |

Each severity level is mapped to an integer index 0–4 (0 = Normal, 4 = Extremely Severe).

### Composite Score Logic

1. For each attempt, compute `composite = dep_severity + anx_severity + str_severity` (range 0–12).
2. `overallDelta = composite_attempt3 − composite_attempt1` (negative = improved, positive = worsened).
3. Additionally count how many of the 3 subscales show an improving or stable per-subscale trend (`improvingCount`).

### Verdict Outcomes (7 possible)

| Condition | trendCode | trendLabel |
|---|---|---|
| `overallDelta ≤ −4` | `improving` | Strong Improvement 🌟 |
| `−4 < overallDelta < 0` | `improving` | Gradual Improvement 🌱 |
| `overallDelta == 0` and `composite3 ≤ 3` | `stable` | Stable & Healthy 💚 |
| `overallDelta == 0` and `composite3 > 3` | `stable` | Stable — Needs Support 💙 |
| `0 < overallDelta ≤ 2` and `improvingCount ≥ 2` | `fluctuating` | Mixed Progress 🔄 |
| `0 < overallDelta ≤ 2` and `improvingCount < 2` | `fluctuating` | Slight Fluctuation ⚡ |
| `overallDelta > 2` | `declining` | Needs Attention ⚠️ |

### Per-Subscale Insight

For each subscale the trend phrase is derived by comparing severity level deltas between attempt 1→2 and 2→3:

| Pattern | Trend phrase |
|---|---|
| Both deltas ≤ 0, sum < 0 | "consistently improved" |
| Both deltas ≥ 0, sum > 0 | "consistently worsened" |
| Delta 1→2 > 0, Delta 2→3 < 0 | "peaked mid-way then improved" |
| Delta 1→2 < 0, Delta 2→3 > 0 | "improved then plateaued" |
| Otherwise | "remained stable" |

The insight also records the raw score progression `(A1 → A2 → A3)` and the final severity label.

---

## MAAS — Mindfulness Checker

**Service class:** `MAASVerdictEngine`  
**Scoring range:** 1.00–6.00 (average of 15 items, each rated 1–6)  
**Direction:** **Higher = better** (more mindful = higher score)

### Classification Thresholds (for subscale insight only)

| Range | Class |
|---|---|
| ≥ 4.5 | High |
| 3.0–4.49 | Average |
| < 3.0 | Low |

### Verdict Outcomes (8 possible)

Computed from `d12 = score2 − score1`, `d23 = score3 − score2`, `overall = score3 − score1`:

| Condition | trendCode | trendLabel |
|---|---|---|
| `d12 > 0.3` and `d23 > 0.3` | `improving` | Consistent Growth 🌟 |
| `overall > 0.75` and `d12 ≤ 0.1` | `improving` | Late Bloomer 🌺 |
| `overall > 0.5` | `improving` | Steady Improvement 🌱 |
| `score1 ≥ 4.0` and `score3 ≥ 4.0` and `|overall| ≤ 0.5` | `stable` | Consistently Mindful 💚 |
| `score1 < 3.5` and `score3 ≥ 4.0` | `improving` | Remarkable Recovery 🏆 |
| `overall < −0.5` and `d12 < −0.2` and `d23 < −0.2` | `declining` | Consistent Decline ⚠️ |
| `overall < −0.5` (other) | `declining` | Overall Decline 💙 |
| Fallthrough | `stable` | Developing Awareness 🔄 |

> Conditions are evaluated in the order listed; the first match wins.

### Subscale Insight

MAAS has a single score, so there is one insight entry:  
`Started: X.XX (Class) → Mid: X.XX → Final: X.XX (Class)`

---

## PWS-18 — Happiness/Wellbeing Checker

**Service class:** `PWS18VerdictEngine`  
**Scoring range:** 1.00–7.00 per subscale (average of 3 items, each rated 1–7; 10 items are reverse-scored using `8 − value`)  
**Direction:** **Higher = better** (greater wellbeing = higher score)

### 6 Subscales

| Subscale | Sinhala |
|---|---|
| Autonomy | ස්වාධීනත්වය |
| Environmental Mastery | පරිසරය කළමනාකරණය |
| Personal Growth | පෞද්ගලික වර්ධනය |
| Positive Relations with Others | අන් අය සමඟ ඇති ධනාත්මක සබඳතා |
| Purpose in Life | ජීවිතයේ අරමුණ |
| Self-Acceptance | තමා පිළිබඳ පිළිගැනීම |

### Level Thresholds (per subscale)

| Range | Level |
|---|---|
| ≥ 5.5 | Flourishing |
| 4.0–5.49 | Developing |
| < 4.0 | Needs Growth |

### Composite Used for Verdict

`avg` = mean of all 6 subscale scores for an attempt.  
`overall = avg3 − avg1`, `d12 = avg2 − avg1`, `d23 = avg3 − avg2`.

### Verdict Outcomes (8 possible)

| Condition | trendCode | trendLabel |
|---|---|---|
| `d12 > 0.4` and `d23 > 0.4` | `improving` | Flourishing Journey 🌟 |
| `overall > 0.5` | `improving` | Growing Wellbeing 🌱 |
| `overall < −0.5` and `d12 < 0` and `d23 < 0` | `declining` | Needs Attention ⚠️ |
| `overall < −0.5` (non-linear) | `declining` | Declining Wellbeing 💙 |
| `avg3 ≥ 5.0` and `|overall| ≤ 0.5` | `stable` | Stable & Flourishing 💚 |
| `d12 > 0.2` and `d23 < −0.2` | `fluctuating` | Peaked Mid-Journey 🔄 |
| `d12 < −0.2` and `d23 > 0.2` | `fluctuating` | Recovering Well 🌺 |
| Fallthrough | `stable` | Steady Progress ⚡ |

> Conditions are evaluated in the order listed; the first match wins.

### Per-Subscale Insights

For each of the 6 subscales the trend phrase is derived from deltas between attempts using `±0.35` thresholds (higher than DASS-21 because the absolute scale is 1–7):

| Pattern | Trend phrase |
|---|---|
| Both deltas > +0.35 | "consistently improved" |
| Both deltas < −0.35 | "consistently declined" |
| Delta 1→2 > +0.2, Delta 2→3 < −0.2 | "improved then dipped" |
| Delta 1→2 < −0.2, Delta 2→3 > +0.2 | "dipped then recovered" |
| Otherwise | "remained stable" |

The insight entry also records the final score and level label. The verdict summary additionally names the **most improved** and **most declined** subscale (by overall delta A3 − A1).

---

## Persistence Flow

```
Provider.loadData()
  └─ attempts loaded (1, 2, 3)
  └─ VerdictFirestoreService.loadVerdict()
       ├─ exists? → return cached QuestionnaireVerdict
       └─ null?   → Engine.compute(attempts)
                    → VerdictFirestoreService.saveVerdict()
                    → return new QuestionnaireVerdict
```

| Questionnaire | Firestore subcollection | Firestore doc |
|---|---|---|
| DASS-21 | `dass21_responses` | `final_verdict` |
| MAAS | `maas_responses` | `final_verdict` |
| PWS-18 | `pws18_responses` | `final_verdict` |

Writes are guarded by `_isCurrentUser()` — the verdict can only be saved for the currently authenticated user.

---

## Display

The computed verdict is rendered on each questionnaire's **start page** via `_buildFinalVerdictCard()`, which selects the English or Sinhala fields based on `langProvider.currentLang == 'si'`. Both the summary text and all subscale insights are fully pre-computed in both languages at engine time — no runtime translation is performed.
