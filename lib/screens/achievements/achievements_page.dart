import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../models/achievement_data.dart';
import '../../widgets/achievements/achievement_progress_header.dart';
import '../../widgets/achievements/achievement_card.dart';
import '../../utils/translate.dart';

class AchievementsPage extends StatelessWidget {
  const AchievementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Access Data
    final authProvider = Provider.of<AuthProvider>(context);
    final langProvider = Provider.of<LanguageProvider>(context);
    final user = authProvider.user;
    final isSinhala = langProvider.currentLang == 'si';

    // Determine Unlocked IDs
    final List<String> unlockedIds = user?.achievements ?? [];

    // Calculate Progress
    final total = AchievementData.allAchievements.length;
    final unlockedCount = unlockedIds.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          context.t.achievements('achievements'),
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: Column(
        children: [
          // TOP SECTION
          AchievementProgressHeader(
            unlockedCount: unlockedCount,
            totalCount: total,
            isSinhala: isSinhala,
          ),

          // BOTTOM SECTION
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: total,
              itemBuilder: (context, index) {
                final achievement = AchievementData.allAchievements[index];
                final isUnlocked = unlockedIds.contains(achievement.id);
                return AchievementCard(
                  achievement: achievement,
                  isUnlocked: isUnlocked,
                  isSinhala: isSinhala,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
