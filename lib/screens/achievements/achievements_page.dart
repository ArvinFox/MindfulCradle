import 'package:flutter/material.dart';
import 'package:mamamind/utils/helpers.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/colors.dart';
import '../../widgets/achievement_tile.dart'; 
import '../../providers/language_provider.dart';

class AchievementsPage extends StatelessWidget {
  const AchievementsPage({super.key});

  static const List<Map<String, dynamic>> achievements = [
    {
      'title_en': "Self-Discovery", 'title_si': "ආත්ම අවබෝධය",
      'subtitle_en': "Completed the Self-Acceptance PWS sub-scale.", 'subtitle_si': "ස්වයං-ග්‍රහණය (Self-Acceptance) PWS උප-මානය සම්පූර්ණ කරන ලදී.",
      'icon': Icons.favorite_border, 'completed': true
    },
    {
      'title_en': "Goal Setter", 'title_si': "ඉලක්ක සකසන්නා",
      'subtitle_en': "Completed the Purpose in Life PWS sub-scale.", 'subtitle_si': "ජීවිතයට අරමුණ (Purpose in Life) PWS උප-මානය සම්පූර්ණ කරන ලදී.",
      'icon': Icons.lightbulb_outline, 'completed': false
    },
    {
      'title_en': "Social Butterfly", 'title_si': "සමාජ පියාපත්",
      'subtitle_en': "Completed the Positive Relations PWS sub-scale.", 'subtitle_si': "අන් අය සමඟ සම්බන්ධතා (Positive Relations) PWS උප-මානය සම්පූර්ණ කරන ලදී.",
      'icon': Icons.group, 'completed': false
    },
    {
      'title_en': "Bilingual Bonus", 'title_si': "භාෂා දීමනාව",
      'subtitle_en': "You changed the app language successfully!", 'subtitle_si': "ඔබ යෙදුමේ භාෂාව සාර්ථකව වෙනස් කරන ලදී!",
      'icon': Icons.translate, 'completed': false
    },
    {
      'title_en': "The Full Picture", 'title_si': "සම්පූර්ණ පින්තූරය",
      'subtitle_en': "Completed all 6 PWS-18 categories. Well done!", 'subtitle_si': "PWS-18 හි සියලුම කාණ්ඩ 6 සම්පූර්ණ කරන ලදී. විශිෂ්ටයි!",
      'icon': Icons.diamond, 'completed': false
    },
  ];

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final isSinhala = langProvider.currentLang == 'si';
    
    final pageTitle = isSinhala ? "ජයග්‍රහණ" : "Achievements";

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          pageTitle,
          style: appBarTextStyle,
        ),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ListView.separated(
          itemCount: achievements.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final ach = achievements[index];

            final title = isSinhala ? ach['title_si'] as String : ach['title_en'] as String;
            final subtitle = isSinhala ? ach['subtitle_si'] as String : ach['subtitle_en'] as String;
            
            return AchievementTile(
              title: title,
              subtitle: subtitle,
              icon: ach['icon'] as IconData,
              iconColor: AppColors.primary,
              isCompleted: ach['completed'] as bool,
            );
          },
        ),
      ),
    );
  }
}
