import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '/constants/colors.dart';
import '../../../providers/dass21_provider.dart';
import '../../../providers/connectivity_provider.dart';
import '/providers/language_provider.dart';
import 'dass21_full_questionnaire.dart';
import '../../../utils/dass21_hints.dart';
import '/widgets/questionnaires/questionnaire_attempt_card.dart';
import '/widgets/questionnaires/questionnaire_intro_screen.dart';
import '/widgets/questionnaires/questionnaire_marquee_title.dart';
import '/widgets/questionnaires/questionnaire_result_tiles.dart';
import '../../../utils/translate.dart';
import '/widgets/app_background.dart';
import '../../../utils/app_snackbar.dart';
import '../../../services/questionnaire_verdict_service.dart'
    show QuestionnaireVerdict;

class DASS21QuestionnaireStartPage extends StatefulWidget {
  const DASS21QuestionnaireStartPage({super.key});

  @override
  State<DASS21QuestionnaireStartPage> createState() =>
      _DASS21QuestionnaireStartPageState();
}

class _DASS21QuestionnaireStartPageState
    extends State<DASS21QuestionnaireStartPage> {
  bool _initialized = false;

  DateTime? _lastBlockedMessageAt;

  // Collapsed State
  final Set<int> _expandedAttempts = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final provider = Provider.of<DASS21Provider>(context, listen: false);
      provider.loadDASS21Data(context);
      _initialized = true;
    }
  }

  // Helper to get Color based on severity
  Color _getSeverityColor(String classification) {
    if (classification.contains('Normal') ||
        classification.contains('සාමාන්‍ය'))
      return const Color(0xFF49AF3F);
    if (classification.contains('Mild') || classification.contains('මදක්'))
      return const Color(0xFFEBCB4B);
    if (classification.contains('Moderate') ||
        classification.contains('මධ්‍යම'))
      return const Color(0xFFFFA500);
    if (classification.contains('Severe') || classification.contains('දරුණු'))
      return const Color(0xFFE76565);
    if (classification.contains('Extremely') ||
        classification.contains('අතිශය'))
      return const Color(0xFFC73030);
    return AppColors.tileInactive;
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final provider = Provider.of<DASS21Provider>(context);
    final hasInternet = Provider.of<ConnectivityProvider>(
      context,
      listen: true,
    ).hasInternet;
    final isSinhala = langProvider.currentLang == 'si';
    final isMobile = MediaQuery.of(context).size.width < 600;

    final titleTextStyle = GoogleFonts.poppins(
      color: AppColors.text,
      fontWeight: FontWeight.w600,
      fontSize: 20,
    );

    // Logic to decide which screen to show
    final hasData =
        provider.unlockDates.isNotEmpty || provider.userAttempts.isNotEmpty;
    final canStart = hasInternet && hasData && !provider.isLoading;
    final helperText = _helperText(isSinhala, hasInternet, hasData);
    bool showIntro = !provider.isLoading && provider.userAttempts.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: QuestionnaireMarqueeTitle(
          text: context.t.questionnaires('feelingsChecker'),
          style: titleTextStyle,
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline, color: AppColors.primary),
            onPressed: () => DASS21HintOverlay.show(context, onClose: () {}),
          ),
        ],
      ),
      body: AppBackground(
        useGradient: true,
        child: provider.isLoading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              )
            : showIntro
            ? QuestionnaireIntroScreen(
                title: context.t.questionnaires('welcomeDASS21'),
                subtitle: context.t.questionnaires('welcomeDASS21Description'),
                buttonText: context.t.questionnaires('startFeedback'),
                isEnabled: canStart,
                helperText: helperText,
                onStart: () {
                  if (!canStart) {
                    _showStartBlockedMessage(
                      context,
                      isSinhala,
                      hasInternet,
                      hasData,
                    );
                    return;
                  }
                  DASS21HintOverlay.show(
                    context,
                    onClose: () {
                      _startQuestionnaire(
                        context,
                        provider,
                        hasInternet,
                        hasData,
                        isSinhala,
                      );
                    },
                  );
                },
                isMobile: isMobile,
              )
            : RefreshIndicator(
                onRefresh: () async => await provider.loadDASS21Data(context),
                color: AppColors.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          context.t.questionnaires('yourProgress'),
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          context.t.questionnaires('assessmentProgress'),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            color: AppColors.text.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // --- Attempt 1 ---
                      _buildAttemptCard(context, 1, provider, isSinhala),

                      // --- Attempt 2 ---
                      _buildAttemptCard(context, 2, provider, isSinhala),

                      // --- Attempt 3 ---
                      _buildAttemptCard(context, 3, provider, isSinhala),

                      // Final Verdict (only when all 3 attempts done)
                      if (provider.finalVerdict != null)
                        _buildFinalVerdictCard(
                          context,
                          provider.finalVerdict!,
                          isSinhala,
                        ),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // ATTEMPT LIST CARD
  Widget _buildAttemptCard(
    BuildContext context,
    int attemptNum,
    DASS21Provider provider,
    bool isSinhala,
  ) {
    bool isCompleted = provider.userAttempts.containsKey(attemptNum);
    DateTime? unlockDate = provider.unlockDates[attemptNum];
    bool isLocked = false;
    String lockReason = '';

    if (!isCompleted) {
      // Check sequential lock (attempt 2 and 3 require previous attempt completion)
      if (attemptNum > 1 &&
          !provider.userAttempts.containsKey(attemptNum - 1)) {
        isLocked = true;
        lockReason = 'sequential';
      }
      // Check time-based lock
      else if (unlockDate != null && DateTime.now().isBefore(unlockDate)) {
        isLocked = true;
        lockReason = 'time';
      }
    }

    String dateStr = context.t.questionnaires('tbd');
    if (unlockDate != null) {
      dateStr = DateFormat('MMM d, yyyy').format(unlockDate);
    }

    // Get Completed Date String
    String completedDateStr = '';
    if (isCompleted) {
      final date = provider.getAttemptDate(attemptNum);
      if (date != null) {
        completedDateStr = DateFormat('MMM d, yyyy').format(date);
      }
    }

    bool isExpanded = _expandedAttempts.contains(attemptNum);

    // Determine status text based on lock reason
    String statusText;
    if (isCompleted) {
      statusText = isExpanded
          ? context.t.questionnaires('hideResults')
          : context.t.questionnaires('viewResults');
    } else if (isLocked) {
      if (lockReason == 'time') {
        statusText = '${context.t.questionnaires('unlocksOn')} $dateStr';
      } else if (lockReason == 'sequential') {
        statusText = context.t.questionnaires('unlocksAfterPrevious');
      } else {
        statusText = context.t.questionnaires('locked');
      }
    } else {
      statusText = context.t.questionnaires('availableNow');
    }

    final completedDateText = completedDateStr.isNotEmpty
        ? '${context.t.questionnaires('completedOn')} $completedDateStr'
        : null;

    return QuestionnaireAttemptCard(
      attemptNumber: attemptNum,
      isSinhala: isSinhala,
      isCompleted: isCompleted,
      isLocked: isLocked,
      isExpanded: isExpanded,
      statusText: statusText,
      completedDateText: completedDateText,
      onToggleExpanded: isCompleted
          ? () {
              setState(() {
                if (isExpanded) {
                  _expandedAttempts.remove(attemptNum);
                } else {
                  _expandedAttempts.add(attemptNum);
                }
              });
            }
          : null,
      onStart: (!isCompleted && !isLocked)
          ? () {
              final hasInternet = Provider.of<ConnectivityProvider>(
                context,
                listen: false,
              ).hasInternet;
              final hasData =
                  provider.unlockDates.isNotEmpty ||
                  provider.userAttempts.isNotEmpty;
              if (!hasInternet || !hasData) {
                _showStartBlockedMessage(
                  context,
                  isSinhala,
                  hasInternet,
                  hasData,
                );
                return;
              }
              DASS21HintOverlay.show(
                context,
                onClose: () {
                  _startQuestionnaire(
                    context,
                    provider,
                    hasInternet,
                    hasData,
                    isSinhala,
                  );
                },
              );
            }
          : null,
      results: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: Color(0xFF2B7CD3),
                ),
                const SizedBox(width: 6),
                Text(
                  context.t.questionnaires('lowerScoresBetter'),
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: const Color(0xFF2B7CD3),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          QuestionnaireResultTile(
            title: context.t.questionnaires('depression'),
            scoreText:
                '${provider.getPastScore(attemptNum, 'depression') ?? 0} / 42',
            classification: provider.classifyDepression(
              provider.getPastScore(attemptNum, 'depression') ?? 0,
              isSinhala: isSinhala,
            ),
            tileColor: _getSeverityColor(
              provider.classifyDepression(
                provider.getPastScore(attemptNum, 'depression') ?? 0,
                isSinhala: isSinhala,
              ),
            ),
            screenWidth: MediaQuery.of(context).size.width,
          ),
          const SizedBox(height: 12),
          QuestionnaireResultTile(
            title: context.t.questionnaires('anxiety'),
            scoreText:
                '${provider.getPastScore(attemptNum, 'anxiety') ?? 0} / 42',
            classification: provider.classifyAnxiety(
              provider.getPastScore(attemptNum, 'anxiety') ?? 0,
              isSinhala: isSinhala,
            ),
            tileColor: _getSeverityColor(
              provider.classifyAnxiety(
                provider.getPastScore(attemptNum, 'anxiety') ?? 0,
                isSinhala: isSinhala,
              ),
            ),
            screenWidth: MediaQuery.of(context).size.width,
          ),
          const SizedBox(height: 12),
          QuestionnaireResultTile(
            title: context.t.questionnaires('stress'),
            scoreText:
                '${provider.getPastScore(attemptNum, 'stress') ?? 0} / 42',
            classification: provider.classifyStress(
              provider.getPastScore(attemptNum, 'stress') ?? 0,
              isSinhala: isSinhala,
            ),
            tileColor: _getSeverityColor(
              provider.classifyStress(
                provider.getPastScore(attemptNum, 'stress') ?? 0,
                isSinhala: isSinhala,
              ),
            ),
            screenWidth: MediaQuery.of(context).size.width,
          ),
        ],
      ),
    );
  }

  // ─── Final Verdict Card ───────────────────────────────────────────────────

  Widget _buildFinalVerdictCard(
    BuildContext context,
    QuestionnaireVerdict verdict,
    bool isSinhala,
  ) {
    final headerColor = _verdictColor(verdict.trendCode);
    final dateStr = DateFormat('MMM d, yyyy').format(verdict.computedAt);
    final label = isSinhala ? verdict.trendLabelSi : verdict.trendLabel;
    final summaryText = isSinhala ? verdict.summarySi : verdict.summary;
    final insights = isSinhala
        ? verdict.subscaleInsightsSi
        : verdict.subscaleInsights;
    final insightsHeader = context.t.questionnaires('subscaleInsights');
    final headerTitle =
        '${verdict.emoji}  ${context.t.questionnaires('finalResultAnalysis')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: headerColor.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: headerColor.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [headerColor, headerColor.withValues(alpha: 0.75)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
            ),
            child: Text(
              headerTitle,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: headerColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: headerColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: headerColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  summaryText,
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: AppColors.text.withValues(alpha: 0.85),
                    height: 1.55,
                  ),
                ),
                if (insights.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Divider(color: AppColors.border, thickness: 1),
                  const SizedBox(height: 10),
                  Text(
                    insightsHeader,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...insights.entries.map((e) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.circle, size: 7, color: headerColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: GoogleFonts.roboto(
                                  fontSize: 13,
                                  color: AppColors.text,
                                  height: 1.45,
                                ),
                                children: [
                                  TextSpan(
                                    text: '${e.key}: ',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  TextSpan(text: e.value),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Generated on $dateStr',
                    style: GoogleFonts.roboto(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _verdictColor(String trendCode) {
    switch (trendCode) {
      case 'improving':
        return AppColors.success;
      case 'stable':
        return AppColors.info;
      case 'fluctuating':
        return AppColors.warning;
      case 'declining':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  void _startQuestionnaire(
    BuildContext context,
    DASS21Provider provider,
    bool hasInternet,
    bool hasData,
    bool isSinhala,
  ) {
    if (!hasInternet || !hasData) {
      _showStartBlockedMessage(context, isSinhala, hasInternet, hasData);
      return;
    }
    provider.responses = List<int?>.filled(21, null);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DASS21FullQuestionnairePage()),
    ).then((_) {
      if (mounted) provider.loadDASS21Data(context);
    });
  }

  String? _helperText(bool isSinhala, bool hasInternet, bool hasData) {
    if (!hasInternet) {
      return context.t.questionnaires('noInternet');
    }
    if (!hasData) {
      return context.t.questionnaires('dataUnavailable');
    }
    return null;
  }

  void _showStartBlockedMessage(
    BuildContext context,
    bool isSinhala,
    bool hasInternet,
    bool hasData,
  ) {
    final now = DateTime.now();
    if (_lastBlockedMessageAt != null &&
        now.difference(_lastBlockedMessageAt!) < const Duration(seconds: 2)) {
      return;
    }
    _lastBlockedMessageAt = now;

    final message = !hasInternet
        ? context.t.questionnaires('noInternet')
        : context.t.questionnaires('dataUnavailable');

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    AppSnackBar.error(context, message);
  }
}
