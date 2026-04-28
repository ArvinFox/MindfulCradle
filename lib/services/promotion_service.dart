import 'dart:math';

/// Manages promotional nudges for Journal, Mood, Meditation, and Evaluations.
///
/// The idle-timer in [MainScreen] controls how often promos appear (2-min idle).
/// This service just picks which type to show.
class PromotionService {
  PromotionService._();

  static const typeJournal = 'journal';
  static const typeMood = 'mood';
  static const typeMeditation = 'meditation';
  static const typeEvaluation = 'evaluation';

  /// Picks a random promotion type to show.
  ///
  /// [hasMoodToday] - user already logged mood today (skip mood promo).
  /// [lastShownType] - the most recently shown type; excluded so the same
  ///   promo is never shown twice in a row (unless it is the only option).
  static Future<String?> pickPromotion({
    required bool hasMoodToday,
    required bool hasJournalEntry,
    required bool hasMeditationProgress,
    bool hasEvaluation = false,
    String? lastShownType,
  }) async {
    final candidates = <String>[];

    // Mood is a daily check-in - only nudge if not done today.
    if (!hasMoodToday) candidates.add(typeMood);
    // All other types are always eligible - the idle timer controls frequency.
    candidates.add(typeJournal);
    candidates.add(typeMeditation);
    candidates.add(typeEvaluation);

    // Avoid repeating the same type back-to-back (only if other options exist).
    if (lastShownType != null && candidates.length > 1) {
      candidates.remove(lastShownType);
    }

    return candidates[Random().nextInt(candidates.length)];
  }

  /// No-op kept for call-site compatibility.
  static Future<void> markShown(String type) async {}
}
