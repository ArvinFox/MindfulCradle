import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '/constants/colors.dart';
import '../../../providers/maas_provider.dart';
import '../../../providers/connectivity_provider.dart';
import '/providers/language_provider.dart';
import 'maas_full_questionnaire.dart';
import 'package:mamamind/utils/maas_hints.dart';
import 'package:mamamind/utils/helpers.dart';
import '/widgets/questionnaires/questionnaire_attempt_card.dart';
import '/widgets/questionnaires/questionnaire_intro_screen.dart';
import '/widgets/questionnaires/questionnaire_marquee_title.dart';
import '/widgets/questionnaires/questionnaire_result_tiles.dart';
import '../../../utils/translate.dart';
import '/utils/app_snackbar.dart';
import '/widgets/app_background.dart';

class MAASQuestionnaireStartPage extends StatefulWidget {
  const MAASQuestionnaireStartPage({super.key});

  @override
  State<MAASQuestionnaireStartPage> createState() =>
      _MAASQuestionnaireStartPageState();
}

class _MAASQuestionnaireStartPageState
    extends State<MAASQuestionnaireStartPage> {
  bool _initialized = false;

  DateTime? _lastBlockedMessageAt;

  final Set<int> _expandedAttempts = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final provider = Provider.of<MAASProvider>(context, listen: false);
      provider.loadMAASData(context);
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final provider = Provider.of<MAASProvider>(context);
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
    final helperText = _helperText(isSinhala, hasInternet, hasData);
    bool showIntro = !provider.isLoading && provider.userAttempts.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: QuestionnaireMarqueeTitle(
          text: context.t.questionnaires('mindfulnessChecker'),
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
            onPressed: () => MAASHintOverlay.show(context, onClose: () {}),
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
                title: context.t.questionnaires('welcomeMindfulness'),
                subtitle: context.t.questionnaires(
                  'welcomeMindfulnessDescription',
                ),
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
                  MAASHintOverlay.show(
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
                onRefresh: () async => await provider.loadMAASData(context),
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
    MAASProvider provider,
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
                _showStartBlockedMessage(
                  context,
                  isSinhala,
                  hasInternet,
                  hasData,
                );
                return;
              }
              MAASHintOverlay.show(
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
      results: QuestionnaireResultTile(
        title: context.t.questionnaires('mindfulnessLevel'),
        scoreText:
            (provider.getAttemptData(attemptNum)?['maasScore'] as num?)
                ?.toDouble()
                .toStringAsFixed(2) ??
            "-",
        classification: _translateClassification(
          (provider.getAttemptData(attemptNum)?['classification'] as String?) ??
              "-",
          isSinhala,
        ),
        tileColor:
            (provider.getAttemptData(attemptNum)?['maasScore'] as num?) != null
            ? scoreToColorMAAS(
                (provider.getAttemptData(attemptNum)?['maasScore'] as num)
                    .toDouble(),
              )
            : AppColors.tileInactive,
        isColumnLayout: true,
        screenWidth: MediaQuery.of(context).size.width,
      ),
    );
  }

  // TRANSLATION HELPER
  String _translateClassification(String classification, bool isSinhala) {
    if (!isSinhala) return classification;

    switch (classification) {
      case 'High Level of Mindfulness':
        return 'සතිමත් බව ඉහළයි';
      case 'Average Level of Mindfulness':
        return 'සතිමත් බව සාමාන්‍යයි';
      case 'Low Level of Mindfulness':
        return 'සතිමත් බව අඩුයි';
      default:
        return classification;
    }
  }

  void _startQuestionnaire(
    BuildContext context,
    MAASProvider provider,
    bool hasInternet,
    bool hasData,
    bool isSinhala,
  ) {
    if (!hasInternet || !hasData) {
      _showStartBlockedMessage(context, isSinhala, hasInternet, hasData);
      return;
    }
    provider.responses = List<int?>.filled(15, null);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MAASFullQuestionnairePage()),
    ).then((_) {
      if (mounted) provider.loadMAASData(context);
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
