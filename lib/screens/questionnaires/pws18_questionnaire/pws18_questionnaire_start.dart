import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '/constants/colors.dart';
import '/providers/pws18_provider.dart';
import '../../../providers/connectivity_provider.dart';
import '/providers/language_provider.dart';
import 'pws18_full_questionnaire.dart';
import '/utils/helpers.dart';
import '/utils/pws18_hints.dart';
import '/widgets/questionnaires/questionnaire_attempt_card.dart';
import '/widgets/questionnaires/questionnaire_intro_screen.dart';
import '/widgets/questionnaires/questionnaire_marquee_title.dart';
import '/widgets/questionnaires/questionnaire_result_tiles.dart';
import '../../../utils/translate.dart';
import '/utils/app_snackbar.dart';
import '/widgets/app_background.dart';
import '../../../services/questionnaire_verdict_service.dart'
    show QuestionnaireVerdict;

class PWS18QuestionnaireStartPage extends StatefulWidget {
  const PWS18QuestionnaireStartPage({super.key});

  @override
  State<PWS18QuestionnaireStartPage> createState() =>
      _PWS18QuestionnaireStartPageState();
}

class _PWS18QuestionnaireStartPageState
    extends State<PWS18QuestionnaireStartPage> {
  bool _initialized = false;

  DateTime? _lastBlockedMessageAt;

  final Set<int> _expandedAttempts = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final provider = Provider.of<PWS18Provider>(context, listen: false);
      provider.loadPWS18Data(context);
      _initialized = true;
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final provider = Provider.of<PWS18Provider>(context);
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

    final hasData =
        provider.unlockDates.isNotEmpty || provider.userAttempts.isNotEmpty;
    final canStart = hasInternet && hasData && !provider.isLoading;
    final helperText = _helperText(context, hasInternet, hasData);
    bool showIntro = !provider.isLoading && provider.userAttempts.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: QuestionnaireMarqueeTitle(
          text: context.t.questionnaires('happinessChecker'),
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
            onPressed: () => PWS18HintOverlay.show(context, onClose: () {}),
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
                title: context.t.questionnaires('welcomeHappiness'),
                subtitle: context.t.questionnaires(
                  'welcomeHappinessDescription',
                ),
                buttonText: context.t.questionnaires('startFeedback'),
                isEnabled: canStart,
                helperText: helperText,
                onStart: () {
                  if (!canStart) {
                    _showStartBlockedMessage(context, hasInternet, hasData);
                    return;
                  }
                  PWS18HintOverlay.show(
                    context,
                    onClose: () {
                      _startQuestionnaire(
                        context,
                        provider,
                        hasInternet,
                        hasData,
                      );
                    },
                  );
                },
                isMobile: isMobile,
              )
            : RefreshIndicator(
                onRefresh: () async => await provider.loadPWS18Data(context),
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

                      // Attempt 1
                      _buildAttemptCard(context, 1, provider, isSinhala),
                      // Attempt 2
                      _buildAttemptCard(context, 2, provider, isSinhala),
                      // Attempt 3
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

  // Attempt Card
  Widget _buildAttemptCard(
    BuildContext context,
    int attemptNum,
    PWS18Provider provider,
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
                _showStartBlockedMessage(context, hasInternet, hasData);
                return;
              }
              PWS18HintOverlay.show(
                context,
                onClose: () {
                  _startQuestionnaire(context, provider, hasInternet, hasData);
                },
              );
            }
          : null,
      results: _buildResultGrid(attemptNum, provider, isSinhala),
    );
  }

  // Result Grid
  Widget _buildResultGrid(
    int attemptNum,
    PWS18Provider provider,
    bool isSinhala,
  ) {
    final scores = provider.getPastScores(attemptNum) ?? {};

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: isSinhala ? 1.1 : 1.5,
      children: provider.subscales.keys.map((key) {
        final score = scores[key];
        final displayTitle = _getSubscaleLabel(context, key);
        final label = score != null ? _pws18LevelLabel(score) : null;

        return QuestionnaireCategoryTile(
          title: displayTitle,
          score: score,
          classification: label,
          outOf: '7',
          tileColor: score != null
              ? scoreToColorPWS18(score)
              : AppColors.tileInactive,
        );
      }).toList(),
    );
  }

  String _pws18LevelLabel(double score) {
    if (score >= 5.5) return 'Flourishing';
    if (score >= 4.0) return 'Developing';
    return 'Needs Growth';
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
    final insightsHeader = isSinhala
        ? 'යටි-ශ්‍රේණි විශ්ලේෂණය'
        : 'Subscale Insights';
    final headerTitle = isSinhala
        ? '${verdict.emoji}  අවසාන ප්‍රතිඵල විශ්ලේෂණය'
        : '${verdict.emoji}  Final Result Analysis';

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
          // ── Header ──────────────────────────────────────────────
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
            child: Row(
              children: [
                Text(
                  headerTitle,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // ── Body ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Verdict label pill
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

                // Summary
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
    PWS18Provider provider,
    bool hasInternet,
    bool hasData,
  ) {
    if (!hasInternet || !hasData) {
      _showStartBlockedMessage(context, hasInternet, hasData);
      return;
    }
    provider.responses = List<int?>.filled(18, null);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PWS18FullQuestionnairePage()),
    ).then((_) {
      if (mounted) provider.loadPWS18Data(context);
    });
  }

  String? _helperText(BuildContext context, bool hasInternet, bool hasData) {
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
