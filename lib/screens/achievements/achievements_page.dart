import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../models/achievement_data.dart';

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
          isSinhala ? "ජයග්‍රහණ" : "Achievements",
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
          _buildProgressHeader(unlockedCount, total, isSinhala),

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
                return _buildAchievementCard(
                  achievement,
                  isUnlocked,
                  isSinhala,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressHeader(int unlocked, int total, bool isSinhala) {
    double percent = total == 0 ? 0 : unlocked / total;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 70,
                height: 70,
                child: CircularProgressIndicator(
                  value: percent,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 8,
                ),
              ),
              Text(
                "${(percent * 100).toInt()}%",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),

          // Text Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSinhala ? "ඔබේ එකතුව" : "Your Collection",
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "$unlocked / $total ${isSinhala ? 'සම්පූර්ණයි' : 'Unlocked'}",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Trophy Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.emoji_events,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  /// The individual Achievement Card
  Widget _buildAchievementCard(
    Achievement item,
    bool isUnlocked,
    bool isSinhala,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isUnlocked ? Colors.white : const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (isUnlocked)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
        border: isUnlocked
            ? Border.all(color: item.color.withOpacity(0.1), width: 1)
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isUnlocked
                  ? item.color.withOpacity(0.15)
                  : Colors.grey[300],
            ),
            child: Icon(
              isUnlocked ? item.icon : Icons.lock,
              size: 28,
              color: isUnlocked ? item.color : Colors.grey[500],
            ),
          ),
          const SizedBox(height: 12),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              isSinhala ? item.titleSi : item.titleEn,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isUnlocked ? AppColors.text : Colors.grey[500],
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Text(
              isSinhala ? item.descriptionSi : item.descriptionEn,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.roboto(
                fontSize: 11,
                color: isUnlocked
                    ? AppColors.text.withOpacity(0.6)
                    : Colors.grey[400],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
