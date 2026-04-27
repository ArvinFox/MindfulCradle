import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:marquee/marquee.dart';
import 'package:mamamind/screens/RAG_Chat/rag_chat_help.dart';
import 'package:mamamind/services/notification_service.dart';
import 'package:provider/provider.dart';

import '../../constants/colors.dart';
import '../../providers/language_provider.dart';
import '../../utils/app_snackbar.dart';
import '../../widgets/connectivity_banner.dart';
import 'achievements/achievements_page.dart';
import 'home/home_page.dart';
import 'home/questionnaires.dart';
import 'profile/profile_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  DateTime? _lastBackPressTime;

  final List<Widget> _pages = const [
    HomePage(),
    QuestionnaireMainPage(),
    ChatBotPage(),
    AchievementsPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
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
    });
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
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
    }) {
      final isSelected = _currentIndex == index;

      return Expanded(
        flex: isSelected ? 2 : 1,
        child: AnimatedContainer(
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
              buildNavItem(index: 0, label: labels[0], icon: icons[0]),
              buildNavItem(index: 1, label: labels[1], icon: icons[1]),
              buildNavItem(index: 2, label: labels[2], icon: icons[2]),
              buildNavItem(index: 3, label: labels[3], icon: icons[3]),
              buildNavItem(index: 4, label: labels[4], icon: icons[4]),
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
    );
  }
}
