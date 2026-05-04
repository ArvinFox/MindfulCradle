import 'dart:convert';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '/constants/colors.dart';
import '/providers/pws18_provider.dart';
import '/providers/language_provider.dart';
import '/utils/pws18_hints.dart';
import '../../../providers/achievement_provider.dart';
import '/widgets/questionnaires/questionnaire_question_card.dart';
import '../../../widgets/connectivity_banner.dart';
import '../../../providers/connectivity_provider.dart';
import '../../../utils/app_snackbar.dart';
import '/widgets/app_background.dart';
import '../../../utils/translate.dart';
import '../../main_screen.dart';

class PWS18FullQuestionnairePage extends StatefulWidget {
  const PWS18FullQuestionnairePage({super.key});

  @override
  State<PWS18FullQuestionnairePage> createState() =>
      _PWS18FullQuestionnairePageState();
}

class _PWS18FullQuestionnairePageState
    extends State<PWS18FullQuestionnairePage> {
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _questions = [];
  Map<String, String> _options = {};
  String _currentLang = 'en';
  bool _loading = true;
  bool _submitting = false;
  int _pageIndex = 0;
  final int _perPage = 6;
  late final LanguageProvider _langProvider;
  bool _attemptedSubmit = false;

  @override
  void initState() {
    super.initState();

    // ENTER IMMERSIVE MODE ---
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _langProvider = Provider.of<LanguageProvider>(context, listen: false);
    _currentLang = _langProvider.currentLang == 'si' ? 'si' : 'en';
    _loadJson(_currentLang);
    _langProvider.addListener(_onLangChanged);

    final provider = Provider.of<PWS18Provider>(context, listen: false);
    if (provider.user != null) {
      provider.resetAndLoad(provider.user!, context: context);
    }
  }

  @override
  void dispose() {
    // EXIT IMMERSIVE MODE ---
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    _langProvider.removeListener(_onLangChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onLangChanged() {
    final lang = _langProvider.currentLang == 'si' ? 'si' : 'en';
    if (lang != _currentLang) {
      _currentLang = lang;
      _loadJson(_currentLang);
    }
  }

  Future<void> _loadJson(String lang) async {
    setState(() => _loading = true);
    try {
      final path = lang == 'en'
          ? 'languages/pws18_en.json'
          : 'languages/pws18_si.json';
      final data = json.decode(await rootBundle.loadString(path));
      final allQuestions = List<Map<String, dynamic>>.from(data['questions']);
      allQuestions.sort((a, b) => (a['id'] as int).compareTo(b['id'] as int));
      setState(() {
        _questions = allQuestions;
        _options = Map<String, String>.from(data['options']);
      });
    } catch (e) {
      if (kDebugMode) debugPrint('PWS18 JSON load error.');
      setState(() {
        _questions = [];
        _options = {};
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> _questionsForPage(int pageIndex) {
    final start = pageIndex * _perPage;
    final end = (start + _perPage).clamp(0, _questions.length);
    return _questions.sublist(start, end);
  }

  bool _pageAnswered(PWS18Provider provider, int pageIndex) {
    return _questionsForPage(
      pageIndex,
    ).every((q) => provider.responses[(q['id'] as int) - 1] != null);
  }

  Future<void> _submitAll(PWS18Provider provider) async {
    setState(() => _submitting = true);
    try {
      final scores = provider.calculateScores();

      // Save silently updates achievements
      await provider.saveAttemptToFirebase(context);

      if (!mounted) return;

      // Show dialog
      _showScoresDialog(scores);
    } catch (e) {
      if (kDebugMode) debugPrint('Error saving questionnaire.');
      AppSnackBar.error(
        context,
        _currentLang == 'si'
            ? 'දෝෂයක් ඇතිවිය. නැවත උත්සාහ කරන්න.'
            : 'Error submitting answers. Try again.',
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // --- Helper to translate PWS Categories ---
  // Get subscale translation
  String _getSubscaleLabel(BuildContext context, String key) {
    switch (key) {
      case 'Autonomy':
        return context.t.questionnaires('autonomy');
      case 'Environmental Mastery':
        return context.t.questionnaires('environmentalMastery');
      case 'Personal Growth':
        return context.t.questionnaires('personalGrowth');
      case 'Positive Relations with Others':
        return context.t.questionnaires('positiveRelations');
      case 'Purpose in Life':
        return context.t.questionnaires('purposeInLife');
      case 'Self-Acceptance':
        return context.t.questionnaires('selfAcceptance');
      default:
        return key;
    }
  }

  // DIALOG LOGIC
  void _showScoresDialog(Map<String, double> scores) {
    final isSinhala = _currentLang == 'si';
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    final double avgScore = scores.isEmpty
        ? 0
        : scores.values.fold(0.0, (sum, v) => sum + v) / scores.length;
    final bool needsSupport = avgScore < 4.5;

    String overallEmoji;
    String overallMsg;
    if (avgScore >= 5.5) {
      overallEmoji = '🌟';
      overallMsg = isSinhala
          ? 'ඔබේ සමස්ත සෞඛ්‍ය සම්පන්නභාවය ඉතා ඉහළ මට්ටමේ ඇත!'
          : 'Your overall wellbeing is flourishing!';
    } else if (avgScore >= 4.0) {
      overallEmoji = '🌱';
      overallMsg = isSinhala
          ? 'ඔබ හොඳ ගමනක් යාමෙන් සිටිනවා. දිගටම ඉදිරියට!'
          : "You're on a good path. Keep growing!";
    } else {
      overallEmoji = '💙';
      overallMsg = isSinhala
          ? 'ඔබේ සෞඛ්‍ය ගමනට MindfulBot ඔබ සමඟ සිටී'
          : 'MindfulBot is here to support your wellbeing journey';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Stack(
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            child: Container(color: Colors.black.withValues(alpha: 0.1)),
          ),
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isSmallScreen ? screenWidth * 0.9 : 380,
                minWidth: screenWidth * 0.8,
              ),
              child: AlertDialog(
                backgroundColor: AppColors.cardBackground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 20,
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(overallEmoji, style: const TextStyle(fontSize: 36)),
                      const SizedBox(height: 8),
                      Text(
                        isSinhala
                            ? 'ඔබේ සෞඛ්‍ය ප්‍රතිඵල'
                            : 'Your Wellbeing Results',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: isSmallScreen ? 20 : 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        overallMsg,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.roboto(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 18),
                      ...scores.entries.map((e) {
                        final displayKey = _getSubscaleLabel(context, e.key);
                        final color = _pws18SubscaleColor(e.value);
                        final String levelLabel = _pws18LevelLabel(
                          e.value,
                          isSinhala,
                        );
                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: color.withValues(alpha: 0.35),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  displayKey,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.text,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  levelLabel,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 16),
                        child: Text(
                          isSinhala
                              ? '💡 ඉහළ ලකුණු = ශ්‍රේෂ්ඨ සෞඛ්‍ය (1–7 ශ්‍රේණිය)'
                              : '💡 Higher scores = greater wellbeing (1–7 scale)',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.roboto(
                            fontSize: 11,
                            color: AppColors.textMuted,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      if (needsSupport) ...[
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: const Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 18,
                            ),
                            label: Text(
                              isSinhala
                                  ? 'MindfulBot සමඟ කතා කරන්න'
                                  : 'Chat with MindfulBot',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: BorderSide(
                                color: AppColors.primary,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () {
                              Navigator.of(context).pop();
                              Navigator.popUntil(
                                context,
                                (route) => route.isFirst,
                              );
                              MainScreen.switchToTab(2);
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: () {
                            final achProvider =
                                Provider.of<AchievementProvider>(
                                  context,
                                  listen: false,
                                );
                            Navigator.of(context).pop();
                            Navigator.of(context).pop();
                            achProvider.showPendingAchievements(context);
                          },
                          child: Text(
                            context.t.questionnaires('ok'),
                            style: GoogleFonts.poppins(
                              color: AppColors.buttonText,
                              fontWeight: FontWeight.w600,
                              fontSize: isSmallScreen ? 15 : 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _pws18SubscaleColor(double score) {
    if (score >= 5.5) return const Color(0xFF49AF3F);
    if (score >= 4.0) return const Color(0xFFCCAA00);
    return const Color(0xFFFFA500);
  }

  String _pws18LevelLabel(double score, bool isSinhala) {
    if (isSinhala) {
      if (score >= 5.5) return 'ශ්‍රේෂ්ඨ';
      if (score >= 4.0) return 'මධ්‍යම';
      return 'දියුණු විය යුතු';
    } else {
      if (score >= 5.5) return 'Flourishing';
      if (score >= 4.0) return 'Developing';
      return 'Needs Growth';
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PWS18Provider>(context);
    final hasInternet = Provider.of<ConnectivityProvider>(context).hasInternet;
    final isMobile = MediaQuery.of(context).size.width < 600;
    final totalQuestions = _questions.length;
    final totalPages = (totalQuestions / _perPage).ceil();
    final isLastPage = _pageIndex >= totalPages - 1;
    final disableSubmit = isLastPage && !hasInternet;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios),
              color: AppColors.primary,
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              context.t.questionnaires('happinessChecker'),
              style: GoogleFonts.poppins(
                color: AppColors.text,
                fontWeight: FontWeight.w600,
                fontSize: isMobile ? 18 : 20,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            centerTitle: true,
          ),
          body: AppBackground(
            child: _loading
                ? Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    child: Column(
                      children: [
                        // Progress header
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${context.t.questionnaires('questions')}: ${(_pageIndex * _perPage) + 1} - ${((_pageIndex * _perPage + _questionsForPage(_pageIndex).length).clamp(0, totalQuestions)).toInt()} ${context.t.questionnaires('questionsOf')} $totalQuestions',
                                style: GoogleFonts.poppins(
                                  color: AppColors.text.withValues(alpha: 0.7),
                                  fontWeight: FontWeight.w500,
                                  fontSize: isMobile ? 14 : 15,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value:
                                      (_pageIndex + 1) /
                                      (totalPages == 0 ? 1 : totalPages),
                                  color: AppColors.primary,
                                  backgroundColor: AppColors.primary.withValues(
                                    alpha: 0.2,
                                  ),
                                  minHeight: 8,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Questions List
                        Expanded(
                          child: ListView.builder(
                            controller: _scrollController,
                            physics: const BouncingScrollPhysics(),
                            itemCount: _questionsForPage(_pageIndex).length,
                            itemBuilder: (context, idx) {
                              final q = _questionsForPage(_pageIndex)[idx];
                              final qId = q['id'] as int;
                              final bool isMissing =
                                  _attemptedSubmit &&
                                  provider.responses[qId - 1] == null;

                              return QuestionnaireQuestionCard(
                                questionId: qId,
                                questionText: q['question'],
                                options: _options,
                                selectedValue: provider.responses[qId - 1],
                                onAnswerSelected: (intVal) {
                                  provider.setAnswer(qId, intVal);
                                },
                                isMissing: isMissing,
                                isMobile: isMobile,
                                missingText:
                                    '* ${context.t.questionnaires('required')}',
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (disableSubmit)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ConnectivityBanner(
                              useSafeArea: false,
                              showShadow: false,
                              borderRadius: BorderRadius.circular(12),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          ),

                        // IMPROVED BUTTON LAYOUT ---
                        Row(
                          children: [
                            FloatingActionButton(
                              mini: true,
                              backgroundColor: AppColors.primary,
                              onPressed: () => PWS18HintOverlay.show(
                                context,
                                onClose: () {},
                              ),
                              elevation: 0,
                              child: Icon(
                                Icons.help_outline,
                                color: AppColors.buttonText,
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Previous Button (Only show if > Page 0)
                            if (_pageIndex > 0) ...[
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _submitting
                                      ? null
                                      : () {
                                          setState(() {
                                            _pageIndex -= 1;
                                            _attemptedSubmit = false;
                                          });
                                          _scrollToTop();
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.tileInactive,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    context.t.questionnaires('previous'),
                                    style: GoogleFonts.poppins(
                                      color: AppColors.text,
                                      fontWeight: FontWeight.w600,
                                      fontSize: isMobile ? 15 : 17,
                                    ),
                                  ),
                                ),
                              ),
                              // Gap between buttons
                              const SizedBox(width: 16),
                            ] else
                              // Push Next button to right on Page 0 without stretching
                              const Spacer(),

                            // Next / Submit Button
                            Expanded(
                              child: ElevatedButton(
                                onPressed: (_submitting || disableSubmit)
                                    ? null
                                    : () {
                                        if (!_pageAnswered(
                                          provider,
                                          _pageIndex,
                                        )) {
                                          setState(
                                            () => _attemptedSubmit = true,
                                          );
                                          AppSnackBar.warning(
                                            context,
                                            context.t.questionnaires(
                                              'pleaseAnswerAll',
                                            ),
                                          );
                                          return;
                                        }
                                        setState(
                                          () => _attemptedSubmit = false,
                                        );
                                        if (_pageIndex < totalPages - 1) {
                                          setState(() => _pageIndex += 1);
                                          _scrollToTop();
                                        } else {
                                          _submitAll(provider);
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  _pageIndex < totalPages - 1
                                      ? context.t.questionnaires('next')
                                      : context.t.questionnaires('submit'),
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: isMobile ? 15 : 17,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
          ),
        ),

        if (_submitting)
          Container(
            color: AppColors.background,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text(
                    context.t.questionnaires('submitting'),
                    style: GoogleFonts.poppins(
                      color: AppColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
          ),
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: ConnectivityBanner(),
        ),
      ],
    );
  }
}
