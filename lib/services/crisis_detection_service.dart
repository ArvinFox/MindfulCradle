import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../utils/journal_analysis.dart';

/// Severity of emotional concern detected in user content.
enum CrisisLevel {
  /// No concerning content detected — no action needed.
  none,

  /// Significant distress detected (hopelessness, loneliness, very sad mood).
  /// Shows wellness recommendations (meditate, assess, chat).
  distress,

  /// Crisis / suicidal ideation keywords detected.
  /// Shows crisis helpline numbers and chat companion.
  crisis,
}

/// Keyword-based crisis and distress detection for journal entries and mood
/// check-ins.  This is a supplementary safety layer — it does NOT replace
/// professional mental-health assessment.
///
/// Detection uses three layers (in priority order):
///  1. Explicit suicidal-ideation / self-harm keywords → [CrisisLevel.crisis]
///  2. Explicit distress keywords (hopeless, lonely, etc.)  → [CrisisLevel.distress]
///  3. Strongly negative overall sentiment (score < −0.5)   → [CrisisLevel.distress]
class CrisisDetectionService {
  CrisisDetectionService._();

  // ── Crisis keywords ────────────────────────────────────────────────────

  static const _crisisEn = [
    'suicid',
    'kill myself',
    'end my life',
    'want to die',
    "don't want to live",
    'rather be dead',
    'not worth living',
    'end it all',
    'take my own life',
    'self harm',
    'self-harm',
    'hurt myself',
    'harm myself',
    'no reason to live',
    'better off dead',
    'wish i was dead',
    'wish i were dead',
    'life is meaningless',
    'want it to end',
    'die right now',
  ];

  static const _crisisSi = [
    // common ways to say "I want to die" / "to die"
    'මිය යාමට',
    'මිය යන්නට',
    'මිය යාම',
    'මිය යනවා',
    'මිය ගිය',
    // "die/dying" verb stems — catches all conjugations (මැරෙන්නට, මැරෙනවා, etc.)
    'මැරෙන්',
    'මරෙන්නට',
    // "end life" variants (with and without space / conjoined forms)
    'ජීවිතය නිමාකරන්නට',
    'ජීවිතය නිමා කරන',
    'ජීවිතය නිමා',
    'ජීවිතය නිම කරන',
    'ජීවිතේ නිමා',
    'ජීවිතේ නිම කරන',
    // "life is over / finished"
    'ජීවිතය අවසන්',
    'ජීවිතේ අවසන්',
    'ජීවිතය ඉවරයි',
    'ජීවිතේ ඉවරයි',
    'ජීවිතය ඉවර',
    'ජීවිතේ ඉවර',
    // "don't want to live"
    'ජීවත්වීමට ආශාවක් නැත',
    'ජීවත්වීමට ඕනේ නෑ',
    'ජීවත් නොවෙමි',
    'ජීවත් නොවිය',
    'ජීවිතය ඕනේ නෑ',
    'ජීවිතය ගන්නෙමි',
    'ජීවිතය ගන්නවා',
    // "take my life / leave life"
    'ජීවිතයෙන් සමුගන',
    'ජීවිතයෙන් ඉවත්',
    'ජීවිතයෙන් නිදහස',
    'ජීවතුන් අතර සිටීමට',
    // "life is worthless / meaningless"
    'ජීවිතය නිෂ්ඵල',
    'ජීවිතය නිකරුණේ',
    'ජීවිතේ නිකරුණේ',
    // "suicide" / "take one's own life"
    'දිවි නසා',
    'සිය දිවි',
    'ආත්ම ඝාතන',
    // "harm/hurt myself"
    'දිවිය නසා',
    'ශරීරයට හානි',
  ];

  // ── Distress keywords ──────────────────────────────────────────────────

  static const _distressEn = [
    'hopeless',
    'helpless',
    'worthless',
    'empty inside',
    'feel empty',
    'feeling empty',
    'broken inside',
    'feel broken',
    'feeling broken',
    'so alone',
    'completely alone',
    'all alone',
    'no one cares',
    'nobody cares',
    'no one understands',
    'nobody understands',
    "can't go on",
    "can't cope",
    'cannot cope',
    'giving up',
    'numb inside',
    'feel numb',
    'feeling numb',
    'lost hope',
    'lost all hope',
    'miserable',
    "don't care anymore",
    'nothing matters',
    'feeling lonely',
    'feel so lonely',
    'feel so lost',
    'no one to talk to',
    'nobody to talk to',
  ];

  static const _distressSi = [
    'හුදෙකලා',
    'කිසිවෙකු නෑ',
    'ශක්තිය නෑ',
    'ජීවිතය කරදර',
    'ඉවසිය නොහැකි',
    'ජීවිතය වේදනාකාරී',
    'ආශාවක් නෑ',
    'නිදහස් නෑ',
    'ක්ලාන්ත',
    'තනිකඩ',
    'කතා කරන්නට කිසිවෙකු නෑ',
    'ආශාව නැත',
  ];

  // ── Regex patterns (catches crisis phrases with inserted words) ─────────
  // e.g. "end my precious life", "end this miserable life"
  static final _crisisEnRegex = [
    RegExp(r'\bend\b.{0,25}\blife\b', caseSensitive: false),
    RegExp(r'\btake\b.{0,15}\bmy\b.{0,10}\blife\b', caseSensitive: false),
    RegExp(r'\bkill\b.{0,10}\bmyself\b', caseSensitive: false),
  ];

  // ── Public API ─────────────────────────────────────────────────────────

  /// Analyzes a journal entry text and returns the detected [CrisisLevel].
  ///
  /// Always checks **both** EN and Si keyword lists so that bilingual users
  /// (who may type in either language regardless of the app language setting)
  /// are always protected.
  static CrisisLevel analyzeJournalText(String text, String lang) {
    if (text.trim().isEmpty) return CrisisLevel.none;

    final lower = text.toLowerCase();

    // Layer 1 — crisis keywords (highest priority).
    // Check English (case-insensitive) and Sinhala (Unicode-sensitive) always.
    for (final kw in _crisisEn) {
      if (lower.contains(kw)) return CrisisLevel.crisis;
    }
    for (final kw in _crisisSi) {
      if (text.contains(kw)) return CrisisLevel.crisis;
    }
    // Regex pass — catches "end my precious life" type phrases.
    for (final pattern in _crisisEnRegex) {
      if (pattern.hasMatch(lower)) return CrisisLevel.crisis;
    }

    // Layer 2 — distress keywords.
    for (final kw in _distressEn) {
      if (lower.contains(kw)) return CrisisLevel.distress;
    }
    for (final kw in _distressSi) {
      if (text.contains(kw)) return CrisisLevel.distress;
    }

    // Layer 3 — strongly negative overall sentiment via JournalAnalysis.
    final result = JournalAnalysis.analyze(text, lang);
    if (result.score < -0.5) {
      return CrisisLevel.distress;
    }

    return CrisisLevel.none;
  }

  /// Analyses a mood check-in and returns the detected [CrisisLevel].
  ///
  /// - Any mood with crisis keywords in the note → [CrisisLevel.crisis]
  /// - Any mood with distress keywords in the note → [CrisisLevel.distress]
  /// - moodIndex <= 1 (Very Sad or Sad) with no concerning note → [CrisisLevel.distress]
  static CrisisLevel analyzeMoodEntry(
    int moodIndex,
    String? note,
    String lang,
  ) {
    // Analyze the optional note text first (keyword priority over index alone)
    if (note != null && note.trim().isNotEmpty) {
      final noteLevel = analyzeJournalText(note.trim(), lang);
      if (noteLevel != CrisisLevel.none) return noteLevel;
    }

    // Very Sad (0) or Sad (1) with no concerning note is still at least distress
    if (moodIndex <= 1) return CrisisLevel.distress;

    return CrisisLevel.none;
  }

  // ── AI-enhanced detection ──────────────────────────────────────────────

  static const String _geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  /// Calls Gemini with a tiny classification-only prompt to detect crisis or
  /// distress in [text].  Returns [CrisisLevel.none] on any error so the
  /// caller can silently fall back to keyword-based detection.
  ///
  /// - Uses `maxOutputTokens: 10` and `temperature: 0.1` for deterministic,
  ///   low-cost results.
  /// - Times out after [timeout] (default 5 s) to avoid blocking the UI.
  static Future<CrisisLevel> analyzeWithAI(
    String text,
    String lang,
    String apiKey, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (apiKey.isEmpty || text.trim().isEmpty) return CrisisLevel.none;

    final prompt =
        '''Analyze the following text for emotional crisis or distress.
Classify as exactly one of: crisis, distress, or none.
Definitions:
- crisis: suicidal thoughts, self-harm intent, immediate danger to life
- distress: hopelessness, emotional pain, severe sadness, feeling overwhelmed or worthless
- none: neutral, mildly negative, or positive content
Reply with ONLY one word: crisis, distress, or none.
Language of text: ${lang == 'si' ? 'Sinhala' : 'English'}
Text: "${text.length > 500 ? text.substring(0, 500) : text}"''';

    try {
      final response = await http
          .post(
            Uri.parse(
              '$_geminiBaseUrl/gemini-2.0-flash-lite:generateContent?key=$apiKey',
            ),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': prompt},
                  ],
                },
              ],
              'generationConfig': {'maxOutputTokens': 10, 'temperature': 0.1},
            }),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final raw =
            (data['candidates']?[0]?['content']?['parts']?[0]?['text']
                        as String? ??
                    '')
                .trim()
                .toLowerCase();
        if (raw.contains('crisis')) return CrisisLevel.crisis;
        if (raw.contains('distress')) return CrisisLevel.distress;
      }
      // Non-200 or unrecognised response → fall back
    } catch (e) {
      // Network error, timeout, quota exceeded, JSON parse failure — all
      // handled silently so the keyword fallback is used.
      if (kDebugMode) {
        debugPrint(
          '[CrisisDetection] AI analysis failed, using keyword fallback: $e',
        );
      }
    }

    return CrisisLevel.none;
  }

  /// Combines keyword-based and AI-based detection, returning the **more
  /// severe** level.  If [apiKey] is empty or AI call fails the keyword result
  /// is used as-is.
  static Future<CrisisLevel> analyzeJournalTextWithAI(
    String text,
    String lang,
    String apiKey,
  ) async {
    final keywordLevel = analyzeJournalText(text, lang);
    // Skip AI call if keywords already flagged a crisis — no need to escalate further
    if (keywordLevel == CrisisLevel.crisis) return CrisisLevel.crisis;

    final aiLevel = await analyzeWithAI(text, lang, apiKey);
    // Return whichever is more severe
    return aiLevel.index > keywordLevel.index ? aiLevel : keywordLevel;
  }

  /// Combines keyword-based and AI-based mood entry detection.
  static Future<CrisisLevel> analyzeMoodEntryWithAI(
    int moodIndex,
    String? note,
    String lang,
    String apiKey,
  ) async {
    final keywordLevel = analyzeMoodEntry(moodIndex, note, lang);
    if (keywordLevel == CrisisLevel.crisis) return CrisisLevel.crisis;

    // Only run AI analysis if there is note text to analyse
    if (note != null && note.trim().isNotEmpty) {
      final aiLevel = await analyzeWithAI(note.trim(), lang, apiKey);
      return aiLevel.index > keywordLevel.index ? aiLevel : keywordLevel;
    }

    return keywordLevel;
  }

  // ── Extended AI: crisis + sentiment in one call ────────────────────────

  /// Calls Gemini to classify both **crisis level** and **sentiment** in a
  /// single prompt, using `gemini-1.5-flash` for higher accuracy.
  ///
  /// Returns a named record `(crisis, sentiment, sentimentScore)`.
  /// On any error the record has `crisis: none`, `sentiment: ''` (caller
  /// keeps the keyword-based sentiment) and `sentimentScore: 0.0`.
  static Future<({CrisisLevel crisis, String sentiment, double sentimentScore})>
  analyzeWithAIExtended(
    String text,
    String lang,
    String apiKey, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    const fallback = (
      crisis: CrisisLevel.none,
      sentiment: '',
      sentimentScore: 0.0,
    );
    if (apiKey.isEmpty || text.trim().isEmpty) return fallback;

    final snippet = text.length > 1000 ? text.substring(0, 1000) : text;
    final langName = lang == 'si' ? 'Sinhala' : 'English';

    final prompt =
        'You are a mental health content classifier for a pregnancy wellness '
        'app. Analyze the journal entry written in $langName.\n\n'
        'Reply with EXACTLY 2 lines:\n'
        'sentiment: [positive/neutral/negative]\n'
        'safety: [crisis/distress/none]\n\n'
        'Definitions:\n'
        '- sentiment positive: happy, grateful, hopeful, calm, joyful\n'
        '- sentiment neutral: factual, mixed, or ambiguous mood\n'
        '- sentiment negative: sad, worried, tired, frustrated, upset\n'
        '- safety crisis: suicidal thoughts, self-harm intent, wanting to die\n'
        '- safety distress: hopeless, worthless, feeling empty, severe sadness,'
        ' cannot cope\n'
        '- safety none: no serious concern\n\n'
        'Journal entry: "$snippet"';

    try {
      final response = await http
          .post(
            Uri.parse(
              '$_geminiBaseUrl/gemini-1.5-flash:generateContent?key=$apiKey',
            ),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': prompt},
                  ],
                },
              ],
              'generationConfig': {'maxOutputTokens': 30, 'temperature': 0.0},
            }),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final raw =
            (data['candidates']?[0]?['content']?['parts']?[0]?['text']
                        as String? ??
                    '')
                .trim()
                .toLowerCase();

        CrisisLevel crisis = CrisisLevel.none;
        String sentiment = '';
        double sentimentScore = 0.0;

        for (final line in raw.split('\n')) {
          final t = line.trim();
          if (t.startsWith('safety:')) {
            final val = t.substring('safety:'.length).trim();
            if (val.contains('crisis')) {
              crisis = CrisisLevel.crisis;
            } else if (val.contains('distress')) {
              crisis = CrisisLevel.distress;
            }
          } else if (t.startsWith('sentiment:')) {
            final val = t.substring('sentiment:'.length).trim();
            if (val.contains('positive')) {
              sentiment = 'positive';
              sentimentScore = 0.7;
            } else if (val.contains('negative')) {
              sentiment = 'negative';
              sentimentScore = -0.7;
            } else if (val.contains('neutral')) {
              sentiment = 'neutral';
              sentimentScore = 0.0;
            }
          }
        }

        return (
          crisis: crisis,
          sentiment: sentiment,
          sentimentScore: sentimentScore,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CrisisDetection] Extended AI failed: $e');
      }
    }

    return fallback;
  }
}
