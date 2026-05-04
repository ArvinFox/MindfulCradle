import 'dart:convert';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '/constants/colors.dart';
import '../../../providers/dass21_provider.dart';
import '/providers/language_provider.dart';
import '../../../utils/dass21_hints.dart';
import '../../../providers/achievement_provider.dart';
import '/widgets/questionnaires/questionnaire_question_card.dart';
import '../../../widgets/connectivity_banner.dart';
import '../../../providers/connectivity_provider.dart';
import '../../../utils/app_snackbar.dart';
import '/widgets/app_background.dart';
import '../../../utils/translate.dart';
import '../../main_screen.dart';

class DASS21FullQuestionnairePage extends StatefulWidget {
  const DASS21FullQuestionnairePage({super.key});

  @override
  State<DASS21FullQuestionnairePage> createState() =>
      _DASS21FullQuestionnairePageState();
}

class _DASS21FullQuestionnairePageState
    extends State<DASS21FullQuestionnairePage> {
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _questions = [];
  Map<String, String> _options = {};
  String _currentLang = 'en';
  bool _loading = true;
  bool _submitting = false;
  int _pageIndex = 0;
  final int _perPage = 7;
  late final LanguageProvider _langProvider;
  bool _attemptedSubmit = false;

  @override
  void initState() {
    super.initState();
    // Enable immersive mode for the questionnaire
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _langProvider = Provider.of<LanguageProvider>(context, listen: false);
    _currentLang = _langProvider.currentLang == 'si' ? 'si' : 'en';
    _loadJson(_currentLang);
    _langProvider.addListener(_onLangChanged);

    final provider = Provider.of<DASS21Provider>(context, listen: false);
    if (provider.user != null) {
      provider.resetAndLoad(provider.user!, context: context);
    }
  }

  @override
  void dispose() {
    // Restore edge-to-edge mode when leaving
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
          ? 'languages/dass21_en.json'
          : 'languages/dass21_si.json';
      final data = json.decode(await rootBundle.loadString(path));
      final allQuestions = List<Map<String, dynamic>>.from(
        data['questions'] ?? [],
      );
      allQuestions.sort((a, b) => (a['id'] as int).compareTo(b['id'] as int));
      setState(() {
        _questions = allQuestions;
        _options = Map<String, String>.from(data['options'] ?? {});
      });
    } catch (e) {
      if (kDebugMode) debugPrint('DASS21 JSON load error.');
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
    final endNum = (start + _perPage).clamp(0, _questions.length);
    final end = endNum.toInt();
    if (start >= _questions.length) return [];
    return _questions.sublist(start, end);
  }

  bool _pageAnswered(DASS21Provider provider, int pageIndex) {
    return _questionsForPage(
      pageIndex,
    ).every((q) => provider.responses[(q['id'] as int) - 1] != null);
  }

  Future<void> _submitAll(DASS21Provider provider) async {
    setState(() => _submitting = true);
    try {
      final scores = provider.calculateScores();
      await provider.saveToFirebase(context);

      if (!mounted) return;
      _showScoresDialog(scores);
    } catch (e) {
      if (kDebugMode) debugPrint('Error saving questionnaire.');
      if (!mounted) return;
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

  void _showScoresDialog(Map<String, int> scores) {
    final isSinhala = _currentLang == 'si';
    final provider = Provider.of<DASS21Provider>(context, listen: false);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    final depScore = scores['depression'] ?? 0;
    final anxScore = scores['anxiety'] ?? 0;
    final stressScore = scores['stress'] ?? 0;

    final depClass = provider.classifyDepression(
      depScore,
      isSinhala: isSinhala,
    );
    final anxClass = provider.classifyAnxiety(anxScore, isSinhala: isSinhala);
    final stressClass = provider.classifyStress(
      stressScore,
      isSinhala: isSinhala,
    );

    final bool hasConcern =
        _dass21IsConcerning(depClass) ||
        _dass21IsConcerning(anxClass) ||
        _dass21IsConcerning(stressClass);

    final String headerEmoji = hasConcern ? '💙' : '🌿';
    final String headerMsg = hasConcern
        ? (isSinhala
              ? 'ඔබ ගෙවන කාලය ගැන අවධානය යොමු කරමු'
              : 'Some areas need a little attention')
        : (isSinhala
              ? 'ඔබ ඉතා හොඳ තත්ත්වයේ සිටිනවා!'
              : "You're doing great across all areas!");

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
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(headerEmoji, style: const TextStyle(fontSize: 36)),
                    const SizedBox(height: 8),
                    Text(
                      isSinhala ? 'ඔබේ ප්‍රතිඵල' : 'Your Results',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: isSmallScreen ? 20 : 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      headerMsg,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildDASS21Tile(
                      context.t.questionnaires('depression'),
                      depClass,
                    ),
                    const SizedBox(height: 10),
                    _buildDASS21Tile(
                      context.t.questionnaires('anxiety'),
                      anxClass,
                    ),
                    const SizedBox(height: 10),
                    _buildDASS21Tile(
                      context.t.questionnaires('stress'),
                      stressClass,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isSinhala
                          ? '💡 අඩු ලකුණු = සෞඛ්‍ය සම්පන්නයි'
                          : '💡 Lower scores = better mental health',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (hasConcern) ...[
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
                          final achProvider = Provider.of<AchievementProvider>(
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
        ],
      ),
    );
  }

  Widget _buildDASS21Tile(String label, String classification) {
    final color = _dass21SeverityColor(classification);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.2),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              classification,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _dass21SeverityColor(String classification) {
    if (classification.contains('Normal') ||
        classification.contains('සාමාන්‍ය')) {
      return const Color(0xFF49AF3F);
    }
    if (classification.contains('Mild') || classification.contains('මදක්')) {
      return const Color(0xFFCCAA00);
    }
    if (classification.contains('Moderate') ||
        classification.contains('මධ්‍යම')) {
      return const Color(0xFFFFA500);
    }
    if (classification.contains('Severe') || classification.contains('දරුණු')) {
      return const Color(0xFFE76565);
    }
    return const Color(0xFFC73030);
  }

  bool _dass21IsConcerning(String classification) {
    return classification.contains('Moderate') ||
        classification.contains('Severe') ||
        classification.contains('Extremely') ||
        classification.contains('මධ්‍යම') ||
        classification.contains('දරුණු') ||
        classification.contains('අතිශය');
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DASS21Provider>(context);
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
              context.t.questionnaires('feelingsChecker'),
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
                        // Progress Header
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
                        Row(
                          children: [
                            FloatingActionButton(
                              mini: true,
                              backgroundColor: AppColors.primary,
                              onPressed: () => DASS21HintOverlay.show(
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

                            // PREVIOUS BUTTON (Only show if > page 0)
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
                              const SizedBox(width: 16),
                            ] else
                              const Spacer(),

                            // NEXT / SUBMIT BUTTON
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
