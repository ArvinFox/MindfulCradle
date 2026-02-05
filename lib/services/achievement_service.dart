import 'package:cloud_firestore/cloud_firestore.dart';

class AchievementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const List<String> _superMomRequiredBadges = [
    'first_step',
    'halfway_there',
    'zen_master',
    'self_aware',
    'mindful_observer',
    'happiness_seeker',
  ];

  Future<List<String>> unlockAchievement({
    required String userId,
    required List<String> currentAchievements,
    required String achievementId,
  }) async {
    final Set<String> existing = currentAchievements.toSet();
    final List<String> achievementsToAdd = [];

    if (!existing.contains(achievementId)) {
      achievementsToAdd.add(achievementId);
      existing.add(achievementId);
    }

    final hasAllRequired = _superMomRequiredBadges.every(existing.contains);
    if (hasAllRequired && !existing.contains('super_mom')) {
      achievementsToAdd.add('super_mom');
      existing.add('super_mom');
    }

    if (achievementsToAdd.isEmpty) return [];

    await _firestore.collection('users').doc(userId).update({
      'achievements': FieldValue.arrayUnion(achievementsToAdd),
    });

    return achievementsToAdd;
  }
}
