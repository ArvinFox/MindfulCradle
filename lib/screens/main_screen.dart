import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:marquee/marquee.dart';
import 'package:mamamind/screens/RAG_Chat/rag_chat_help.dart';
import 'package:mamamind/services/notification_service.dart';
import 'package:mamamind/services/promotion_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constants/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dass21_provider.dart';
import '../../providers/journal_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/mood_provider.dart';
import '../../providers/video_provider.dart';
import '../../utils/app_snackbar.dart';
import '../../widgets/connectivity_banner.dart';
import '../../widgets/promo_bottom_card.dart';
import '../../widgets/tutorial/coach_mark_tutorial.dart';
import 'journal/journal_list_screen.dart';
import 'mood/mood_tracker_screen.dart';
import 'achievements/achievements_page.dart';
import 'home/home_page.dart';
import 'home/questionnaires.dart';
import 'profile/profile_page.dart';

class MainScreen extends StatefulWidget {
  /// Optionally open a specific tab on launch.
  /// 0=Home, 1=Questionnaires, 2=Chat, 3=Achievements, 4=Profile
  final int initialTab;

  const MainScreen({super.key, this.initialTab = 0});

  /// Switch the active tab from anywhere in the widget tree without pushing
  /// a new route (avoids rendering tabs outside the MainScreen scaffold).
  static void switchToTab(int index) {
    _MainScreenState._instance?._switchTab(index);
  }

  /// Call from the video player's [initState]/[dispose] to pause/resume
  /// the idle-based promo timer while the user is watching a session.
  static void setVideoPlayerOpen(bool open) {
    _MainScreenState._instance?._onVideoPlayerStateChanged(open);
  }

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  /// Single active instance — used by [MainScreen.switchToTab] and
  /// [MainScreen.setVideoPlayerOpen].
  static _MainScreenState? _instance;

  late int _currentIndex;
  DateTime? _lastBackPressTime;
  bool _tutorialActive = false;

  // ── Idle-based promotion system ──────────────────────────────────────
  /// 2-minute idle threshold before showing a promo.
  static const _idleThreshold = Duration(minutes: 2);

  Timer? _idleTimer;
  bool _promoShowing = false;
  bool _videoPlayerOpen = false;
  String? _lastPromoType;

  // GlobalKeys for each nav-bar item — used by the tutorial spotlight.
  final _navKey0 = GlobalKey(); // Home
  final _navKey1 = GlobalKey(); // Feedback
  final _navKey2 = GlobalKey(); // Chat
  final _navKey3 = GlobalKey(); // Achievements
  final _navKey4 = GlobalKey(); // Profile

  late List<TutorialStep> _tutorialSteps;

  final List<Widget> _pages = const [
    HomePage(),
    QuestionnaireMainPage(),
    ChatBotPage(),
    AchievementsPage(),
    ProfilePage(),
  ];

  void _switchTab(int index) {
    if (mounted) setState(() => _currentIndex = index.clamp(0, 4));
  }

  // ── Idle timer helpers ──────────────────────────────────────────────

  /// Resets the idle timer on every user touch. Called by the [Listener]
  /// wrapping the main scaffold.
  void _onUserActivity() {
    if (_promoShowing || _videoPlayerOpen || _tutorialActive) return;
    _idleTimer?.cancel();
    _idleTimer = Timer(_idleThreshold, _onIdle);
  }

  void _onVideoPlayerStateChanged(bool open) {
    _videoPlayerOpen = open;
    if (open) {
      // Pause the idle timer while the video player is open.
      _idleTimer?.cancel();
    } else {
      // Restart timer when returning from the video player.
      _onUserActivity();
    }
  }

  Future<void> _onIdle() async {
    if (!mounted || _promoShowing || _videoPlayerOpen || _tutorialActive) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('tutorial_done') ?? true)) return;
    if (!mounted) return;

    final moodProvider = Provider.of<MoodProvider>(context, listen: false);
    final journalProvider = Provider.of<JournalProvider>(
      context,
      listen: false,
    );
    final videoProvider = Provider.of<VideoProvider>(context, listen: false);

    final type = await PromotionService.pickPromotion(
      hasMoodToday: moodProvider.hasCheckedInToday,
      hasJournalEntry: journalProvider.entries.isNotEmpty,
      hasMeditationProgress: _completedVideoCount(videoProvider) > 0,
      hasEvaluation: Provider.of<DASS21Provider>(
        context,
        listen: false,
      ).userAttempts.isNotEmpty,
      lastShownType: _lastPromoType,
    );
    if (!mounted) return;
    if (type == null) {
      // No eligible type right now — retry after the normal idle period.
      _onUserActivity();
      return;
    }

    _lastPromoType = type;
    _promoShowing = true;
    await PromotionService.markShown(type);
    try {
      await _showPromotionDialog(type);
    } finally {
      // Always reset — even if the dialog throws or is dismissed unexpectedly.
      _promoShowing = false;
      _onUserActivity();
    }
  }

  int _completedVideoCount(VideoProvider provider) {
    int count = 0;
    for (final video in provider.videos) {
      final watched = provider.userProgress[video.id] ?? 0;
      if (watched >= ((video.duration * 0.9).ceil())) count++;
    }
    return count;
  }

  // ── Promotion dialog ────────────────────────────────────────────────

  Future<void> _showPromotionDialog(String type) async {
    if (!mounted) return;
    final isSinhala =
        Provider.of<LanguageProvider>(context, listen: false).currentLang ==
        'si';
    final content = _promoContent(type, isSinhala);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.32),
      builder: (_) => PromoBottomCard(
        data: content,
        onAction: () {
          Navigator.of(context).pop();
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
        _switchTab(0);
        // Brief delay so the home tab finishes rendering before the toast appears.
        Future.delayed(const Duration(milliseconds: 350), () {
          if (!mounted) return;
          AppSnackBar.info(
            context,
            Provider.of<LanguageProvider>(context, listen: false).currentLang ==
                    'si'
                ? 'ක්ෂය-ශෛලී ධ්‍යාන සැසි ඉහළින් ඇත 🧘‍♀️'
                : 'Meditation sessions are right below — give one a try! 🧘‍♀️',
            duration: const Duration(seconds: 4),
          );
        });
        break;
      case PromotionService.typeEvaluation:
        _switchTab(1);
        break;
    }
  }

  PromoCardData _promoContent(String type, bool isSinhala) {
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
        return PromoCardData(
          emoji: '📖',
          title: isSinhala ? 'සඟරාව ලියන්නද?' : 'Time to journal?',
          message: msgs[rng.nextInt(msgs.length)],
          color: const Color(0xFF2D9D78),
          actionLabel: isSinhala ? 'ලිවීමට යමු' : "Let's Write",
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
                "Don't forget your daily mood check-in!",
              ];
        return PromoCardData(
          emoji: '🌸',
          title: isSinhala ? 'මනෝ සටහනක්?' : 'Mood check-in!',
          message: msgs[rng.nextInt(msgs.length)],
          color: const Color(0xFFE28E28),
          actionLabel: isSinhala ? 'සටහන් කරන්න' : 'Log My Mood',
        );

      case PromotionService.typeEvaluation:
        final evalMsgs = isSinhala
            ? [
                'ඔබේ සෞඛ්‍ය ගමන ගැන සරල ඇගයීමක් ලබා ගන්න',
                'කෙටි ඇගයීමකින් ඔබේ දියුණුව දැන ගන්න',
                'ඔබ ගැනම කෙටි ඇගයීමක් ලබා ගැනීම ඔබේ සෞඛ්‍යයට ප්‍රයෝජනවත්',
              ]
            : [
                "A gentle check on how you've been feeling lately",
                "See how you're progressing — it only takes a moment",
                'A little self-reflection can go a long way',
              ];
        return PromoCardData(
          emoji: '🌿',
          title: isSinhala ? 'ඔබ ගැන ඇගයීමක්?' : 'A little check-in?',
          message: evalMsgs[rng.nextInt(evalMsgs.length)],
          color: const Color(0xFF7B68EE),
          actionLabel: isSinhala ? 'ඇගයීමට යමු' : "Let's See",
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
        return PromoCardData(
          emoji: '🧘‍♀️',
          title: isSinhala ? 'ධ්‍යාන කරන්නද?' : 'Time to meditate?',
          message: msgs[rng.nextInt(msgs.length)],
          color: AppColors.primary,
          actionLabel: isSinhala ? 'ධ්‍යානයට යමු' : "Let's Meditate",
        );
    }
  }

  @override
  void initState() {
    super.initState();
    _instance = this;
    _currentIndex = widget.initialTab.clamp(0, 4);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await NotificationService().requestPermissions();

      final prefs = await SharedPreferences.getInstance();
      bool tutorialDone = prefs.getBool('tutorial_done') ?? true;

      // Even if local prefs says done, verify with Firestore.
      // This handles reinstalls, new devices, or the app being closed
      // before the tutorial finished (Firestore still has isTutorialDone=false).
      if (tutorialDone && mounted) {
        try {
          final auth = Provider.of<AuthProvider>(context, listen: false);
          final uid = auth.user?.id;
          if (uid != null) {
            final doc = await FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .get();
            final firestoreDone =
                doc.data()?['isTutorialDone'] as bool? ?? true;
            if (!firestoreDone) {
              await prefs.setBool('tutorial_done', false);
              tutorialDone = false;
            }
          }
        } catch (_) {
          // On Firestore error, trust local prefs.
        }
      }

      if (!tutorialDone && mounted) {
        _buildTutorialSteps();
        setState(() => _tutorialActive = true);
      } else if (mounted) {
        // Tutorial already done — start the idle-based promo timer.
        _onUserActivity();
      }
    });
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _instance = null;
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  void _buildTutorialSteps() {
    _tutorialSteps = [
      // 0 — Welcome (no spotlight)
      const TutorialStep(
        switchToTab: 0,
        titleEn: 'Welcome to Mindful Cradle! 🌿',
        titleSi: 'Mindful Cradle වෙත සාදරයෙන්! 🌿',
        descEn:
            "Let's take a quick tour so you know exactly what's available. Tap 'Start Tour' to begin — or 'Skip' to go straight to the app.",
        descSi:
            'ඔබට ලබා ගත හැකි සියල්ල ගැන ඉක්මන් සංචාරයක් කරමු. \'සංචාරය ආරම්භ\' ක්ලික් කරන්න, නැතිනම් \'මඟ හරින්න\' ක්ලික් කරන්න.',
      ),
      // 1 — Home nav
      TutorialStep(
        switchToTab: 0,
        navKey: _navKey0,
        titleEn: 'Home',
        titleSi: 'මුල් පිටුව',
        descEn:
            'This is your main hub. Watch guided mindfulness videos and quickly access mood logging and your journal.',
        descSi:
            'මෙය ඔබේ ප්‍රධාන hub. Mindfulness වීඩියෝ නරඹන්න සහ mood logging සහ ජර්නල් වෙත ඉක්මනින් ප්‍රවේශ වන්න.',
      ),
      // 2 — Mood & Journal quick-access row (appears just below the hero card)
      TutorialStep(
        switchToTab: 0,
        relRect: const RelRect(0.03, 0.30, 0.97, 0.52),
        padding: 6,
        titleEn: 'Mood & Journal',
        titleSi: 'Mood සහ ජර්නල්',
        descEn:
            'Log your mood daily and write journal entries here. Tracking your emotions helps you understand your wellbeing journey.',
        descSi:
            'ඔබේ දෛනික mood log කරන්න සහ ජර්නල් ලිවීමට මෙය භාවිතා කරන්න. ඔබේ emotions track කිරීම wellbeing ගමන් තේරුම් ගැනීමට උදවු කරයි.',
      ),
      // 3 — Mindfulness Sessions (section header + video grid, below the quick-access row)
      TutorialStep(
        switchToTab: 0,
        relRect: const RelRect(0.03, 0.51, 0.97, 0.85),
        padding: 6,
        titleEn: 'Mindfulness Sessions',
        titleSi: 'Mindfulness සැසි',
        descEn:
            'Watch curated guided meditation videos here. Sessions unlock one by one as you complete each — tap any tile to start.',
        descSi:
            'Guided meditation වීඩියෝ මෙතනින් නරඹන්න. සැසි ක්‍රමිකව unlock වෙනවා — ඕනෑම tile එකක් click කරන්න.',
      ),
      // 4 — Push notifications (spotlights the notification bell icon)
      TutorialStep(
        switchToTab: 0,
        navKey: HomePage.notificationIconKey,
        padding: 10,
        titleEn: 'Stay in the Loop 🔔',
        titleSi: 'දැනුවත්ව සිටින්න 🔔',
        descEn:
            "We'll send you helpful tips, wellness reminders, and important updates directly as notifications. Make sure notifications are allowed so you never miss a thing!",
        descSi:
            'ඔබේ සෞඛ්‍ය ගමනට සහය වීමට අපි ප්‍රයෝජනවත් ඉඟි, reminders, සහ වැදගත් updates notification ලෙස යවමු. කිසිවක් මඟ නොහැරෙනු ඇතැයි notifications allow කිරීමට වග බලා ගන්න!',
      ),
      // 5 — Questionnaires nav
      TutorialStep(
        switchToTab: 1,
        navKey: _navKey1,
        titleEn: 'Mental Health Assessments',
        titleSi: 'මානසික සෞඛ්‍ය ඇගයීම්',
        descEn:
            'Complete evidence-based questionnaires like DASS-21, MAAS & PWS-18 to monitor your emotional and psychological wellbeing over time.',
        descSi:
            'DASS-21, MAAS සහ PWS-18 ප්‍රශ්නාවලිය සම්පූර්ණ කර ඔබේ මානසික සෞඛ්‍යය නිරීක්ෂණය කරන්න.',
      ),
      // 6 — Chat nav
      TutorialStep(
        switchToTab: 2,
        navKey: _navKey2,
        titleEn: 'AI Companion',
        titleSi: 'AI සහකාරයා',
        descEn:
            'Ask our AI chatbot anything about pregnancy, mental health, or everyday concerns. It is available anytime you need support.',
        descSi:
            'ගැබ්ගෙන සිටීම, මානසික සෞඛ්‍යය හෝ දෛනික ගැටළු ගැන AI chatbot ගෙන් ඕනෑ දෙයක් අසන්න.',
      ),
      // 7 — Achievements nav
      TutorialStep(
        switchToTab: 3,
        navKey: _navKey3,
        titleEn: 'Achievements',
        titleSi: 'ජයග්‍රහණ',
        descEn:
            'Earn badges as you complete sessions, log moods, write journals, and take assessments. Celebrate every milestone on your journey!',
        descSi:
            'සැසි සම්පූර්ණ කිරීමෙන්, mood log කිරීමෙන්, ජර්නල් ලිවීමෙන් badges earn කරන්න. ඔබේ ගමනේ සෑම සන්ධිස්ථානයක්ම සමරන්න!',
      ),
      // 8 — Profile nav
      TutorialStep(
        switchToTab: 4,
        navKey: _navKey4,
        titleEn: 'Profile & Settings',
        titleSi: 'ප්‍රොෆයිල් සහ සැකසුම්',
        descEn:
            'Set your profile photo, manage your account, switch between English and Sinhala, set notification reminders, and control your privacy settings.',
        descSi:
            'ප්‍රොෆයිල් ඡායාරූපය සකසන්න, account manage කරන්න, ඉංග්‍රීසි සහ සිංහල අතර භාෂාව මාරු කරන්න, notifications set කරන්න, සහ privacy settings control කරන්න.',
      ),
      // 9 — Done (no spotlight)
      const TutorialStep(
        switchToTab: 0,
        titleEn: "You're all set!",
        titleSi: 'ඔබ සූදානම්!',
        descEn:
            "Your mindfulness journey starts now. Everything is here whenever you need it. Enjoy Mindful Cradle!",
        descSi:
            'ඔබේ mindfulness ගමන දැන් ආරම්භ වෙනවා. ඔබට ඕනෑ ඕනෑ සෑම විටම සියල්ල මෙහි ඇත. Mindful Cradle enjoy කරන්න!',
      ),
    ];
  }

  List<String> _labels(bool isSinhala) {
    return isSinhala
        ? ['මුල් පිටුව', 'ප්‍රතිචාර', 'චැට්', 'ජයග්‍රහණ', 'ප්‍රොෆයිල්']
        : ['Home', 'Feedback', 'Chat', 'Achievements', 'Profile'];
  }

  Widget _buildBottomNavigationBar(bool isSinhala) {
    final labels = _labels(isSinhala);
    const icons = [
      Icons.home_outlined,
      Icons.assignment_outlined,
      Icons.chat_bubble_outline_rounded,
      Icons.workspace_premium_outlined,
      Icons.person_outline_rounded,
    ];

    Widget buildNavItem({
      required int index,
      required String label,
      required IconData icon,
      Key? itemKey,
    }) {
      final isSelected = _currentIndex == index;

      return Expanded(
        flex: isSelected ? 2 : 1,
        child: AnimatedContainer(
          key: itemKey,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _currentIndex = index);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                height: 48,
                padding: EdgeInsets.symmetric(horizontal: isSelected ? 14 : 0),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 24,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textMuted,
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final textStyle = GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            );

                            final maxWidth = constraints.maxWidth;
                            if (!maxWidth.isFinite || maxWidth <= 0) {
                              return Text(
                                label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textStyle,
                              );
                            }

                            final painter = TextPainter(
                              text: TextSpan(text: label, style: textStyle),
                              maxLines: 1,
                              textDirection: Directionality.of(context),
                            )..layout(maxWidth: maxWidth);

                            final shouldMarquee = painter.didExceedMaxLines;

                            if (!shouldMarquee) {
                              return Text(
                                label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textStyle,
                              );
                            }

                            return SizedBox(
                              height: 18,
                              child: Marquee(
                                text: label,
                                blankSpace: 18,
                                velocity: 22,
                                startAfter: const Duration(milliseconds: 650),
                                pauseAfterRound: const Duration(
                                  milliseconds: 800,
                                ),
                                style: textStyle,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Row(
            children: [
              buildNavItem(
                index: 0,
                label: labels[0],
                icon: icons[0],
                itemKey: _navKey0,
              ),
              buildNavItem(
                index: 1,
                label: labels[1],
                icon: icons[1],
                itemKey: _navKey1,
              ),
              buildNavItem(
                index: 2,
                label: labels[2],
                icon: icons[2],
                itemKey: _navKey2,
              ),
              buildNavItem(
                index: 3,
                label: labels[3],
                icon: icons[3],
                itemKey: _navKey3,
              ),
              buildNavItem(
                index: 4,
                label: labels[4],
                icon: icons[4],
                itemKey: _navKey4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final isSinhala = langProvider.currentLang == 'si';

    final exitMessage = isSinhala
        ? 'යෙදුමෙන් පිටවීමට නැවත පිටුපස ඔබන්න'
        : 'Press back again to exit app';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        if (_currentIndex != 0) {
          HapticFeedback.lightImpact();
          setState(() => _currentIndex = 0);
          return;
        }

        final now = DateTime.now();
        if (_lastBackPressTime == null ||
            now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
          HapticFeedback.mediumImpact();
          _lastBackPressTime = now;

          AppSnackBar.neutral(
            context,
            exitMessage,
            duration: const Duration(seconds: 2),
          );
          return;
        }

        SystemNavigator.pop();
      },
      child: Stack(
        children: [
          // ── Main app ──────────────────────────────────────────
          AbsorbPointer(
            absorbing: _tutorialActive,
            child: Listener(
              onPointerDown: (_) => _onUserActivity(),
              child: Scaffold(
                backgroundColor: Colors.transparent,
                extendBody: true,
                body: Stack(
                  children: [
                    const Positioned.fill(
                      child: ColoredBox(color: AppColors.background),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      child: _pages[_currentIndex],
                    ),
                    const Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: ConnectivityBanner(),
                    ),
                  ],
                ),
                bottomNavigationBar: _buildBottomNavigationBar(isSinhala),
              ),
            ),
          ),

          // ── Coach-mark tutorial overlay ───────────────────────
          if (_tutorialActive)
            CoachMarkTutorial(
              steps: _tutorialSteps,
              onTabSwitch: (idx) => setState(() => _currentIndex = idx),
              onDone: () {
                setState(() => _tutorialActive = false);
                // Tutorial just completed — start the idle promo timer.
                _onUserActivity();
              },
            ),
        ],
      ),
    );
  }
}

// ── _PromotionDialog and _PromoContentData moved to lib/widgets/promo_bottom_card.dart ──
