import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/colors.dart';

/// Modern onboarding screen shown once on first launch.
/// Set [onboardingComplete = true] in SharedPreferences on finish.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const String _prefKey = 'onboarding_complete';

  static const List<_OnboardingPageData> _pages = [
    _OnboardingPageData(
      icon: Icons.favorite_rounded,
      accentColor: AppColors.heroGradientStart,
      title: 'Welcome to\nMindful Cradle',
      subtitle:
          'Your caring companion throughout pregnancy. Track your wellbeing, access support, and grow every day.',
    ),
    _OnboardingPageData(
      icon: Icons.insights_rounded,
      accentColor: Color(0xFF2B7CD3),
      title: 'Track Your\nWellbeing',
      subtitle:
          'Complete evidence-based assessments like DASS-21, MAAS and PWS-18 to understand and monitor your mental health journey.',
    ),
    _OnboardingPageData(
      icon: Icons.smart_toy_rounded,
      accentColor: Color(0xFF2D9D78),
      title: 'Your AI\nCompanion',
      subtitle:
          'Ask our AI-powered chatbot anything about pregnancy, mental health, or everyday concerns — anytime you need support.',
    ),
    _OnboardingPageData(
      icon: Icons.emoji_events_rounded,
      accentColor: Color(0xFFE28E28),
      title: 'Achieve &\nGrow',
      subtitle:
          'Unlock achievements, watch curated videos, and celebrate every milestone on your journey to a healthier you.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, true);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _skipOnboarding() {
    HapticFeedback.lightImpact();
    _finishOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      body: Stack(
        children: [
          // Background gradient blobs
          Positioned(
            top: -size.height * 0.12,
            right: -size.width * 0.25,
            child: Container(
              width: size.width * 0.7,
              height: size.width * 0.7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.heroGradientStart.withValues(alpha: 0.15),
              ),
            ),
          ),
          Positioned(
            bottom: -size.height * 0.08,
            left: -size.width * 0.2,
            child: Container(
              width: size.width * 0.65,
              height: size.width * 0.65,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: 0.13),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                // Skip button
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8, right: 16),
                    child: TextButton(
                      onPressed: isLastPage ? null : _skipOnboarding,
                      child: Text(
                        'Skip',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isLastPage
                              ? Colors.transparent
                              : AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                ),

                // Page view
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    itemBuilder: (context, index) {
                      return _OnboardingPage(
                        data: _pages[index],
                        pageIndex: index,
                        isActive: index == _currentPage,
                      );
                    },
                  ),
                ),

                // Bottom section: indicators + button
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                  child: Column(
                    children: [
                      // Page indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_pages.length, (index) {
                          final isActive = index == _currentPage;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 280),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: isActive ? 28 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppColors.primary
                                  : AppColors.border,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 28),

                      // Action button
                      GestureDetector(
                        onTap: _nextPage,
                        child: Container(
                          width: double.infinity,
                          height: 54,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                AppColors.heroGradientStart,
                                AppColors.heroGradientEnd,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(
                                  alpha: 0.35,
                                ),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              isLastPage ? 'Get Started' : 'Next',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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

class _OnboardingPage extends StatelessWidget {
  final _OnboardingPageData data;
  final int pageIndex;
  final bool isActive;

  const _OnboardingPage({
    required this.data,
    required this.pageIndex,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final iconContainerSize = isMobile
        ? (size.width * 0.38).clamp(130.0, 180.0)
        : 200.0;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 28 : 48,
        vertical: 8,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon hero card
          AnimatedScale(
            scale: isActive ? 1.0 : 0.92,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
            child: Container(
              width: iconContainerSize,
              height: iconContainerSize,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    data.accentColor,
                    data.accentColor.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(36),
                boxShadow: [
                  BoxShadow(
                    color: data.accentColor.withValues(alpha: 0.28),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Icon(
                data.icon,
                color: Colors.white,
                size: iconContainerSize * 0.46,
              ),
            ),
          ),
          SizedBox(height: isMobile ? 36 : 48),

          // Title
          AnimatedOpacity(
            opacity: isActive ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 400),
            child: Text(
              data.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: isMobile
                    ? (size.width * 0.072).clamp(24.0, 32.0)
                    : 36.0,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
                height: 1.25,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Subtitle
          AnimatedOpacity(
            opacity: isActive ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 500),
            child: Text(
              data.subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                fontSize: isMobile
                    ? (size.width * 0.038).clamp(13.0, 16.0)
                    : 17.0,
                color: AppColors.textMuted,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPageData {
  final IconData icon;
  final Color accentColor;
  final String title;
  final String subtitle;

  const _OnboardingPageData({
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.subtitle,
  });
}
