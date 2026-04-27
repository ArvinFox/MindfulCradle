import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mamamind/constants/app_config.dart';
import 'package:mamamind/constants/colors.dart';
import 'package:mamamind/providers/auth_provider.dart';
import 'package:mamamind/providers/journal_provider.dart';
import 'package:mamamind/providers/language_provider.dart';
import 'package:mamamind/providers/mood_provider.dart';
import 'package:mamamind/providers/video_provider.dart';
import 'package:mamamind/routes/home_routes.dart';
import 'package:mamamind/utils/logout_util.dart';
import 'package:mamamind/utils/translate.dart';
import 'package:mamamind/utils/app_snackbar.dart';
import 'package:mamamind/widgets/video_tile.dart';
import '../../services/promotion_service.dart';
import 'package:provider/provider.dart';

import '../profile/notification_settings_screen.dart';
import '../journal/journal_list_screen.dart';
import '../mood/mood_tracker_screen.dart';
import '../../widgets/app_background.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _loading = true;
  bool _compactTiles = true;
  bool _promoShown = false;
  late VoidCallback _authListener;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initHome());
  }

  Future<void> _initHome() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final videoProvider = Provider.of<VideoProvider>(context, listen: false);
    final journalProvider = Provider.of<JournalProvider>(
      context,
      listen: false,
    );
    final moodProvider = Provider.of<MoodProvider>(context, listen: false);

    while (authProvider.isInitializing) {
      await Future.delayed(const Duration(milliseconds: 50));
    }

    _authListener = () {
      if (!mounted) return;
      final user = authProvider.user;
      if (user != null && videoProvider.user?.id != user.id) {
        videoProvider.reset();
        videoProvider.setUser(user, context);
      }
    };
    authProvider.addListener(_authListener);

    final user = authProvider.user;
    if (user != null && mounted && videoProvider.user?.id != user.id) {
      videoProvider.reset();
      videoProvider.setUser(user, context);
    }

    // Load journal and mood for home page summary cards
    if (user != null) {
      journalProvider.load(user.id);
      moodProvider.load(user.id);
    }

    if (mounted) {
      setState(() => _loading = false);
      _schedulePromotion();
    }
  }

  void _schedulePromotion() {
    // Show a gentle nudge after a random 15–30s delay — only once per session.
    final delayMs = 15000 + Random().nextInt(15000);
    Future.delayed(Duration(milliseconds: delayMs), _triggerPromotion);
  }

  Future<void> _triggerPromotion() async {
    if (!mounted || _promoShown) return;
    final moodProvider = Provider.of<MoodProvider>(context, listen: false);
    final journalProvider = Provider.of<JournalProvider>(
      context,
      listen: false,
    );
    final videoProvider = Provider.of<VideoProvider>(context, listen: false);

    final type = await PromotionService.pickPromotion(
      hasMoodToday: moodProvider.hasCheckedInToday,
      hasJournalEntry: journalProvider.entries.isNotEmpty,
      hasMeditationProgress: _completedCount(videoProvider) > 0,
    );
    if (type == null || !mounted) return;

    _promoShown = true;
    await PromotionService.markShown(type);
    await _showPromotionDialog(type);
  }

  Future<void> _showPromotionDialog(String type) async {
    if (!mounted) return;
    final isSinhala =
        Provider.of<LanguageProvider>(context, listen: false).currentLang ==
        'si';
    final content = _promoContent(type, isSinhala);

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withValues(alpha: 0.32),
      transitionDuration: const Duration(milliseconds: 360),
      transitionBuilder: (_, anim, __, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      ),
      pageBuilder: (ctx, _, __) => _PromotionDialog(
        content: content,
        onAction: () {
          Navigator.of(ctx).pop();
          _handlePromoAction(type);
        },
      ),
    );
  }

  void _handlePromoAction(String type) {
    if (!mounted) return;
    switch (type) {
      case PromotionService.typeJournal:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const JournalListScreen()),
        );
        break;
      case PromotionService.typeMood:
        showMoodCheckInDialog(context);
        break;
      case PromotionService.typeMeditation:
        // Meditation sessions are already on the home page — show a brief hint.
        AppSnackBar.info(
          context,
          Provider.of<LanguageProvider>(context, listen: false).currentLang ==
                  'si'
              ? 'ක්ෂය-ශෛලී ධ්‍යාන සැසි ඉහළින් ඇත 🧘‍♀️'
              : 'Meditation sessions are right below — give one a try! 🧘‍♀️',
          duration: const Duration(seconds: 4),
        );
        break;
    }
  }

  _PromoContentData _promoContent(String type, bool isSinhala) {
    final rng = Random();
    switch (type) {
      case PromotionService.typeJournal:
        final msgs = isSinhala
            ? [
                'ලිවීම ආතතිය අඩු කිරීමට උදව් කරයි',
                'ඔබේ හැඟීම් සඟරාවේ සටහන් කරන්න',
                'ලිපි කිහිපයක් ඔබේ මනෝ සෞඛ්‍යය වැඩිදියුණු කරයි',
              ]
            : [
                'Writing just a few lines can ease anxiety',
                'Your thoughts deserve a safe space',
                'A few words a day keeps stress away',
              ];
        return _PromoContentData(
          emoji: '📖',
          title: isSinhala ? 'සඟරාව ලියන්නද?' : 'Time to journal?',
          message: msgs[rng.nextInt(msgs.length)],
          color: const Color(0xFF2D9D78),
          actionLabel: isSinhala ? 'ලිවීමට යමු' : 'Let\'s Write',
        );

      case PromotionService.typeMood:
        final msgs = isSinhala
            ? [
                'ඔබ අද කෙසේ ද? ඔබේ දිනය සටහන් කරන්න',
                'ඔබේ හැඟීම් නිරීක්ෂණය ගර්භනී කාලය සඳහා ඉතා වැදගත්',
                'ඔබේ මනෝ ගමන ලිඛිත ලෙස නිරීක්ෂණය කරන්න',
              ]
            : [
                'How are you feeling right now?',
                'Tracking your mood supports your wellbeing',
                'Don\'t forget your daily mood check-in!',
              ];
        return _PromoContentData(
          emoji: '🌸',
          title: isSinhala ? 'මනෝ සටහනක්?' : 'Mood check-in!',
          message: msgs[rng.nextInt(msgs.length)],
          color: const Color(0xFFE28E28),
          actionLabel: isSinhala ? 'සටහන් කරන්න' : 'Log My Mood',
        );

      default: // typeMeditation
        final msgs = isSinhala
            ? [
                'මිනිත්තු 5ක ධ්‍යානයක් ඔබේ දිනය සතුටකින් ආරම්භ කරයි',
                'ශ්වාසය ගෙන ඔබේ ශරීරය සන්සුන් කරන්න',
                'ධ්‍යාන සැසියකට ඔබේ ශරීරය ඉල්ලා සිටියි',
              ]
            : [
                'A 5-minute meditation can transform your day',
                'Take a mindful moment just for you',
                'Your body is asking for a peaceful pause',
              ];
        return _PromoContentData(
          emoji: '🧘‍♀️',
          title: isSinhala ? 'ධ්‍යාන කරන්නද?' : 'Time to meditate?',
          message: msgs[rng.nextInt(msgs.length)],
          color: AppColors.primary,
          actionLabel: isSinhala ? 'ධ්‍යානයට යමු' : 'Let\'s Meditate',
        );
    }
  }

  @override
  void dispose() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.removeListener(_authListener);
    super.dispose();
  }

  Future<void> _refreshHome() async {
    final videoProvider = Provider.of<VideoProvider>(context, listen: false);
    final user = videoProvider.user;
    if (user == null) return;

    videoProvider.reset();
    videoProvider.setUser(user, context);
    await videoProvider.waitForInitialProgress();

    if (mounted) {
      setState(() {});
    }
  }

  int _completedCount(VideoProvider provider) {
    int completed = 0;
    for (final video in provider.videos) {
      final watched = provider.userProgress[video.id] ?? 0;
      if (watched >= ((video.duration * 0.9).ceil())) {
        completed++;
      }
    }
    return completed;
  }

  int _unlockedCount(VideoProvider provider) {
    int unlocked = 0;
    for (final video in provider.videos) {
      if (provider.isVideoUnlocked(video)) {
        unlocked++;
      }
    }
    return unlocked;
  }

  String _firstName(String fullName) {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) return '';
    final parts = trimmed.split(RegExp(r'\s+'));
    return parts.first;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final videoProvider = Provider.of<VideoProvider>(context);
    final langProvider = Provider.of<LanguageProvider>(context);

    final user = videoProvider.user;
    final videos = videoProvider.videos;
    final completed = _completedCount(videoProvider);
    final unlocked = _unlockedCount(videoProvider);
    final progress = videos.isEmpty ? 0.0 : completed / videos.length;
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final currentLang = langProvider.currentLang;

    if (_loading || authProvider.isInitializing) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text(
            context.t.home('userDataLoadingFailed'),
            style: GoogleFonts.roboto(color: AppColors.textMuted),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          AppConfig.appName,
          style: GoogleFonts.poppins(
            color: AppColors.text,
            fontWeight: FontWeight.w600,
            fontSize: 21,
          ),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        iconTheme: const IconThemeData(color: AppColors.text),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            tooltip: context.t.notifications('notificationSettings'),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationSettingsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: context.t.common('logout'),
            onPressed: () {
              HapticFeedback.lightImpact();
              LogoutUtils.showLogoutDialog(
                context: context,
                authProvider: authProvider,
                language: langProvider.currentLang,
                redirectRoute: '/login',
              );
            },
          ),
        ],
      ),
      body: AppBackground(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _refreshHome,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
                  child: _buildHeroCard(
                    firstName: _firstName(user.fullName),
                    completed: completed,
                    unlocked: unlocked,
                    total: videos.length,
                    progress: progress,
                    isMobile: isMobile,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                  child: _buildQuickAccessRow(isMobile, currentLang),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.t.home('meditationSessions'),
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.text,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              context.t.home('selectSession'),
                              style: GoogleFonts.roboto(
                                fontSize: 13,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      _buildLayoutToggle(),
                    ],
                  ),
                ),
              ),
              if (videos.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(context),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    8,
                    20,
                    28 + MediaQuery.of(context).padding.bottom,
                  ),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isMobile
                          ? (_compactTiles ? 2 : 1)
                          : (_compactTiles ? 3 : 2),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: _compactTiles ? 1.0 : 2.25,
                    ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final video = videos[index];
                      final isUnlocked = videoProvider.isVideoUnlocked(video);

                      return VideoTile(
                        title: currentLang == 'en'
                            ? video.title
                            : video.titleSi,
                        isLocked: !isUnlocked,
                        isMobile: isMobile,
                        sessionIndex: index,
                        onTap: isUnlocked
                            ? () {
                                HapticFeedback.lightImpact();
                                final youtubeId = video.getYoutubeId(
                                  currentLang,
                                );
                                HomeRoutes.goToVideoPlayer(
                                  context,
                                  video,
                                  user.id,
                                  youtubeId,
                                );
                              }
                            : () {
                                AppSnackBar.warning(
                                  context,
                                  context.t.home('completePreviousSession'),
                                  duration: const Duration(seconds: 2),
                                );
                              },
                      );
                    }, childCount: videos.length),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Journal + Mood quick-access row ───────────────────────────────────

  Widget _buildQuickAccessRow(bool isMobile, String lang) {
    final isSinhala = lang == 'si';
    final journalProvider = Provider.of<JournalProvider>(context);
    final moodProvider = Provider.of<MoodProvider>(context);

    return Row(
      children: [
        Expanded(child: _buildJournalCard(journalProvider, isSinhala)),
        const SizedBox(width: 12),
        Expanded(child: _buildMoodCard(moodProvider, isSinhala)),
      ],
    );
  }

  Widget _buildJournalCard(JournalProvider provider, bool isSinhala) {
    final count = provider.entries.length;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const JournalListScreen()),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.book_rounded,
                  color: Color(0xFF2D9D78),
                  size: 22,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isSinhala ? 'සඟරාව' : 'Journal',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                count == 0
                    ? (isSinhala ? 'ලිපි නැත' : 'No entries yet')
                    : (isSinhala ? '$count ලිපි' : '$count entries'),
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isSinhala ? 'ලිඛිත විශ්ලේෂණය' : 'Sentiment analysis',
                style: GoogleFonts.roboto(
                  fontSize: 11,
                  color: const Color(0xFF2D9D78),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoodCard(MoodProvider provider, bool isSinhala) {
    final todayMood = provider.todayMood;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () async {
          HapticFeedback.lightImpact();
          if (!provider.hasCheckedInToday) {
            await showMoodCheckInDialog(context);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MoodTrackerScreen()),
            );
          }
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    todayMood?.emoji ?? '🌸',
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isSinhala ? 'මනෝ සටහන' : 'Mood',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                todayMood == null
                    ? (isSinhala ? 'සටහන් කරන්න' : 'Not logged today')
                    : (isSinhala ? todayMood.labelSi() : todayMood.labelEn()),
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                todayMood == null
                    ? (isSinhala ? 'ස්පර්ශ කර සටහන් කරන්න' : 'Tap to log')
                    : (isSinhala ? 'ඉතිහාස බලන්න' : 'View history'),
                style: GoogleFonts.roboto(
                  fontSize: 11,
                  color: const Color(0xFFE28E28),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────

  Widget _buildHeroCard({
    required String firstName,
    required int completed,
    required int unlocked,
    required int total,
    required double progress,
    required bool isMobile,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 18 : 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.heroGradientStart,
            AppColors.heroGradientMid,
            AppColors.heroGradientEnd,
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.30),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${context.t.home('welcome')}, $firstName!",
            style: GoogleFonts.poppins(
              fontSize: isMobile ? 24 : 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.t.home('welcomeMessage'),
            style: GoogleFonts.roboto(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatChip(
                  title: context.t.home('completed'),
                  value: '$completed/$total',
                  icon: Icons.check_circle_outline_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatChip(
                  title: context.t.home('unlocked'),
                  value: '$unlocked',
                  icon: Icons.lock_open_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.24),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.progressValue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLayoutToggle() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        onPressed: () {
          HapticFeedback.selectionClick();
          setState(() {
            _compactTiles = !_compactTiles;
          });
        },
        icon: Icon(
          _compactTiles ? Icons.view_agenda_rounded : Icons.grid_view_rounded,
          color: AppColors.primary,
        ),
        tooltip: context.t.home('toggleLayout'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.self_improvement_rounded,
                size: 34,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              context.t.home('noSessionsAvailable'),
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.roboto(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.95),
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Promotion helpers ──────────────────────────────────────────────────────

class _PromoContentData {
  final String emoji;
  final String title;
  final String message;
  final Color color;
  final String actionLabel;

  const _PromoContentData({
    required this.emoji,
    required this.title,
    required this.message,
    required this.color,
    required this.actionLabel,
  });
}

/// Gentle floating card that nudges the user toward a feature.
/// Appears at the bottom of the screen without blocking the content above.
class _PromotionDialog extends StatelessWidget {
  final _PromoContentData content;
  final VoidCallback onAction;

  const _PromotionDialog({required this.content, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          28 + MediaQuery.viewPaddingOf(context).bottom,
        ),
        child: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 34,
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon bubble
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: content.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Center(
                        child: Text(
                          content.emoji,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            content.title,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            content.message,
                            style: GoogleFonts.roboto(
                              fontSize: 13,
                              color: AppColors.textMuted,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Close
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: AppColors.textMuted.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textMuted,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Skip',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: onAction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: content.color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          content.actionLabel,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
