import 'package:flutter/material.dart';

class Achievement {
  final String id;
  final String titleEn;
  final String titleSi;
  final String descriptionEn;
  final String descriptionSi;
  final IconData icon;
  final Color color;

  const Achievement({
    required this.id,
    required this.titleEn,
    required this.titleSi,
    required this.descriptionEn,
    required this.descriptionSi,
    required this.icon,
    required this.color,
  });
}

// MASTER LIST OF ACHIEVEMENTS
class AchievementData {
  static const List<Achievement> allAchievements = [
    // VIDEO MILESTONES
    Achievement(
      id: 'first_step',
      titleEn: 'First Step',
      titleSi: 'පළමු පියවර',
      descriptionEn: 'Watched the first meditation video.',
      descriptionSi: 'පළමු භාවනා වීඩියෝව නරඹා ඇත.',
      icon: Icons.play_circle_fill,
      color: Color(0xFF7F5AF0),
    ),
    Achievement(
      id: 'halfway_there',
      titleEn: 'Halfway There',
      titleSi: 'අඩක් නිමයි',
      descriptionEn: 'Completed 4 meditation videos.',
      descriptionSi: 'භාවනා වීඩියෝ 4ක් සම්පූර්ණ කර ඇත.',
      icon: Icons.star_half_rounded,
      color: Color(0xFFFFA500),
    ),
    Achievement(
      id: 'zen_master',
      titleEn: 'Zen Mom',
      titleSi: 'සන්සුන් මව',
      descriptionEn: 'Completed all 8 meditation videos!',
      descriptionSi: 'සියලුම භාවනා වීඩියෝ 8 සම්පූර්ණ කර ඇත!',
      icon: Icons.self_improvement,
      color: Color(0xFF49AF3F),
    ),

    // QUESTIONNAIRE MILESTONES
    Achievement(
      id: 'self_aware',
      titleEn: 'Self Aware',
      titleSi: 'ස්වයං අවබෝධය',
      descriptionEn: 'Completed the first attempt of DASS-21.',
      descriptionSi: 'DASS-21 පළමු පියවර සම්පූර්ණ කර ඇත.',
      icon: Icons.psychology,
      color: Color(0xFFEBCB4B), // Gold
    ),
    Achievement(
      id: 'mindful_observer',
      titleEn: 'Mindful Observer',
      titleSi: 'සිහිකල්පනාව',
      descriptionEn: 'Completed the first attempt of MAAS.',
      descriptionSi: 'MAAS පළමු පියවර සම්පූර්ණ කර ඇත.',
      icon: Icons.visibility,
      color: Color(0xFF2CB67D), // Teal
    ),
    Achievement(
      id: 'happiness_seeker',
      titleEn: 'Happiness Seeker',
      titleSi: 'සතුට සොයන්නා',
      descriptionEn: 'Completed the first attempt of PWS-18.',
      descriptionSi: 'PWS-18 පළමු පියවර සම්පූර්ණ කර ඇත.',
      icon: Icons.sentiment_very_satisfied,
      color: Color(0xFFEF4565), // Pink/Red
    ),
    
    // SPECIAL
    Achievement(
      id: 'super_mom',
      titleEn: 'Super Mom',
      titleSi: 'සුපිරි අම්මා',
      descriptionEn: 'Completed all video and assessments!',
      descriptionSi: 'සියලුම වීඩියෝ සහ ඇගයීම් සම්පූර්ණ කර ඇත!',
      icon: Icons.diamond,
      color: Color(0xFF3DA9FC), // Blue
    ),
  ];

  /// Helper to find an achievement by ID
  static Achievement? findById(String id) {
    try {
      return allAchievements.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }
}