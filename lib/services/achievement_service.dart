import 'package:flutter/foundation.dart';
import 'backend_api_service.dart';

class AchievementService {
  /// Unlocks an achievement via the backend, which validates eligibility
  /// and handles the super_mom chain server-side.
  Future<List<String>> unlockAchievement({
    required String userId,
    required List<String> currentAchievements,
    required String achievementId,
  }) async {
    try {
      return await BackendApiService.unlockAchievement(achievementId);
    } catch (e) {
      if (kDebugMode) debugPrint('Achievement unlock error: $e');
      return [];
    }
  }
}
