import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../utils/journal_analysis.dart';

/// Severity of emotional concern detected in user content.
enum CrisisLevel {
  /// No concerning content detected.
  none,

  /// Significant distress detected (hopelessness, loneliness, very sad mood).
  distress,

  /// Crisis or suicidal ideation keywords detected.
  crisis,
}

/// Keyword-based crisis and distress detection for journal entries and mood check-ins.
/// Supplementary safety layer — does not replace professional mental-health assessment.
class CrisisDetectionService {
  CrisisDetectionService._();

  static bool _keywordsLoaded = false;
  static const String _keywordsAssetPath = 'assets/data/crisis_keywords.json';

  // Crisis keywords — populated from JSON on first loadKeywords() call.
  static List<String> _crisisEn = [
    'suicid',
    'kill myself',
    'end my life',
    'want to die',
    "don't want to live",
    'self harm',
    'self-harm',
    'hurt myself',
  ];
  static List<String> _crisisSi = [
    'මිය යාමට',
    'මිය යන්නට',
    'දිවි නසා',
    'සිය දිවි',
    'ආත්ම ඝාතන',
  ];
  static List<String> _distressEn = [
    'hopeless',
    'helpless',
    'worthless',
    'so alone',
    'no one cares',
    'giving up',
    'miserable',
  ];
  static List<String> _distressSi = [
    'හුදෙකලා',
    'කිසිවෙකු නෑ',
    'ශක්තිය නෑ',
    'ඉවසිය නොහැකි',
    'ආශාවක් නෑ',
  ];

  /// Loads all keyword lists from [assets/data/crisis_keywords.json].
  /// Call once at app startup (e.g. in main.dart). Safe to call multiple times.
  static Future<void> loadKeywords() async {
    if (_keywordsLoaded) return;
    try {
      final raw = await rootBundle.loadString(_keywordsAssetPath);
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final crisis = data['crisis'] as Map<String, dynamic>;
      final distress = data['distress'] as Map<String, dynamic>;
      _crisisEn = List<String>.from(crisis['en'] as List);
      _crisisSi = List<String>.from(crisis['si'] as List);
      _distressEn = List<String>.from(distress['en'] as List);
      _distressSi = List<String>.from(distress['si'] as List);
      _keywordsLoaded = true;
    } catch (e) {
      // Keep the compact fallback lists if the asset fails to load.
      if (kDebugMode)
        debugPrint('[CrisisDetection] Failed to load keywords JSON: $e');
    }
  }

  // Regex patterns — catches crisis phrases with inserted words (e.g. "end my precious life")
  static final _crisisEnRegex = [
    RegExp(r'\bend\b.{0,25}\blife\b', caseSensitive: false),
    RegExp(r'\btake\b.{0,15}\bmy\b.{0,10}\blife\b', caseSensitive: false),
    RegExp(r'\bkill\b.{0,10}\bmyself\b', caseSensitive: false),
  ];

  // Public API

  /// Analyzes journal text and returns the detected [CrisisLevel].
  /// Always checks both EN and Sinhala keyword lists regardless of app language.
  static CrisisLevel analyzeJournalText(String text, String lang) {
    if (text.trim().isEmpty) return CrisisLevel.none;

    final lower = text.toLowerCase();

    // Layer 1 — crisis keywords (highest priority).
    for (final kw in _crisisEn) {
      if (lower.contains(kw)) return CrisisLevel.crisis;
    }
    for (final kw in _crisisSi) {
      if (text.contains(kw)) return CrisisLevel.crisis;
    }
    // Regex pass — catches phrases with inserted words.
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

  /// Analyzes a mood check-in and returns the detected [CrisisLevel].
  /// moodIndex <= 1 (Very Sad/Sad) with no concerning note → distress.
  static CrisisLevel analyzeMoodEntry(
    int moodIndex,
    String? note,
    String lang,
  ) {
    // Check note text first (keywords take priority over mood index).
    if (note != null && note.trim().isNotEmpty) {
      final noteLevel = analyzeJournalText(note.trim(), lang);
      if (noteLevel != CrisisLevel.none) return noteLevel;
    }

    // Sad mood with no crisis/distress note is still distress.
    if (moodIndex <= 1) return CrisisLevel.distress;

    return CrisisLevel.none;
  }

  // AI-enhanced detection

  static const String _geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  /// Calls Gemini to classify text as crisis, distress, or none.
  /// Returns [CrisisLevel.none] on any error so keyword fallback is used.
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
      // Non-200 or unrecognised response — fall back to keyword detection.
    } catch (e) {
      // Any error (network, timeout, quota, parse) — handled silently.
      if (kDebugMode) {
        debugPrint(
          '[CrisisDetection] AI analysis failed, using keyword fallback: $e',
        );
      }
    }

    return CrisisLevel.none;
  }
}
