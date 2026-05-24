import 'dart:math';

/// Picks promotional nudges for Journal, Mood, Meditation, and Evaluations.
class PromotionService {
  PromotionService._();

  static const typeJournal = 'journal';
  static const typeMood = 'mood';
  static const typeMeditation = 'meditation';
  static const typeEvaluation = 'evaluation';

  /// Picks a random promotion type, excluding lastShownType to avoid repeats.
  /// Skips mood promo if hasMoodToday is true.
  static Future<String?> pickPromotion({
    required bool hasMoodToday,
    required bool hasJournalEntry,
    required bool hasMeditationProgress,
    bool hasEvaluation = false,
    String? lastShownType,
  }) async {
    final candidates = <String>[];

    // Only nudge for mood if not already done today.
    if (!hasMoodToday) candidates.add(typeMood);
    // Other types are always eligible.
    candidates.add(typeJournal);
    candidates.add(typeMeditation);
    candidates.add(typeEvaluation);

    // Avoid showing the same type twice in a row.
    if (lastShownType != null && candidates.length > 1) {
      candidates.remove(lastShownType);
    }

    return candidates[Random().nextInt(candidates.length)];
  }

  /// No-op kept for call-site compatibility.
  static Future<void> markShown(String type) async {}
}
