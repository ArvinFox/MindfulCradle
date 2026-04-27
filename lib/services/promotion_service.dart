import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages gentle, session-spaced promotional nudges for Journal, Mood, and Meditation.
///
/// Rules:
/// - Same type is not shown more than once every 4 hours.
/// - Only types that have not yet been completed (today) are considered.
/// - A random candidate is picked for variety.
class PromotionService {
  PromotionService._();

  static const typeJournal = 'journal';
  static const typeMood = 'mood';
  static const typeMeditation = 'meditation';

  /// 4 hours minimum between showing the same promotion type.
  static const _minGapMs = 4 * 60 * 60 * 1000;

  /// Picks the next promotion to show, or null if nothing is needed.
  ///
  /// [hasMoodToday]          – user already logged mood today.
  /// [hasJournalEntry]       – user has at least one journal entry overall.
  /// [hasMeditationProgress] – user has completed at least one meditation.
  static Future<String?> pickPromotion({
    required bool hasMoodToday,
    required bool hasJournalEntry,
    required bool hasMeditationProgress,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    final candidates = <String>[];

    // Priority order: mood (daily check-in) > journal > meditation.
    if (!hasMoodToday && _canShow(prefs, typeMood, now)) {
      candidates.add(typeMood);
    }
    if (!hasJournalEntry && _canShow(prefs, typeJournal, now)) {
      candidates.add(typeJournal);
    }
    if (!hasMeditationProgress && _canShow(prefs, typeMeditation, now)) {
      candidates.add(typeMeditation);
    }

    if (candidates.isEmpty) return null;
    return candidates[Random().nextInt(candidates.length)];
  }

  static bool _canShow(SharedPreferences prefs, String type, int now) {
    final last = prefs.getInt('promo_last_$type') ?? 0;
    return (now - last) > _minGapMs;
  }

  /// Call after the dialog is displayed so we don't show it again too soon.
  static Future<void> markShown(String type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      'promo_last_$type',
      DateTime.now().millisecondsSinceEpoch,
    );
  }
}
