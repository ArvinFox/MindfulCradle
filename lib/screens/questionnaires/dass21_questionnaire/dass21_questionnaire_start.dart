import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '/constants/colors.dart';
import '../../../providers/dass21_provider.dart';
import '/providers/language_provider.dart';
import 'dass21_full_questionnaire.dart';
import '../../../utils/dass21_hints.dart';
import '/widgets/questionnaires/questionnaire_attempt_card.dart';
import '/widgets/questionnaires/questionnaire_intro_screen.dart';
import '/widgets/questionnaires/questionnaire_marquee_title.dart';
import '/widgets/questionnaires/questionnaire_result_tiles.dart';

class DASS21QuestionnaireStartPage extends StatefulWidget {
  const DASS21QuestionnaireStartPage({super.key});

  @override
  State<DASS21QuestionnaireStartPage> createState() =>
      _DASS21QuestionnaireStartPageState();
}

class _DASS21QuestionnaireStartPageState
    extends State<DASS21QuestionnaireStartPage> {
  bool _initialized = false;

  // Hint State
  bool _showHint = false;
  bool _navigateAfterHint = false;

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
    final isSinhala = langProvider.currentLang == 'si';
    final isMobile = MediaQuery.of(context).size.width < 600;

    final titleTextStyle = GoogleFonts.poppins(
      color: Colors.white,
      fontWeight: FontWeight.w600,
      fontSize: 20,
    );

    // Logic to decide which screen to show
    bool showIntro = !provider.isLoading && provider.userAttempts.isEmpty;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: QuestionnaireMarqueeTitle(
              text: isSinhala ? 'හැඟීම් පරික්ෂාව' : 'Feelings Checker',
              style: titleTextStyle,
            ),
            centerTitle: true,
            backgroundColor: AppColors.primary,
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.help_outline, color: Colors.white),
                onPressed: () => setState(() {
                  _showHint = true;
                  _navigateAfterHint = false;
                }),
              ),
            ],
          ),
          body: provider.isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                )
              : showIntro
              ? QuestionnaireIntroScreen(
                  title: isSinhala
                      ? 'හැඟීම් පරීක්ෂාව (DASS-21) වෙත සාදරයෙන් පිළිගනිමු!'
                      : 'Welcome to Feelings Checker (DASS-21)',
                  subtitle: isSinhala
                      ? 'මෙම ප්‍රශ්නාවලිය ඔබේ මානසික අවපීඩන, කාංසාව, පීඩනය මට්ටම් පිළිබඳ විශ්ලේෂණයක් ලබා දේ.'
                      : 'This questionnaire provides insights into your Depression, Anxiety, and Stress levels.',
                  buttonText: isSinhala
                      ? 'ප්‍රතිචාර ආරම්භ කරන්න'
                      : 'Start Feedback',
                  onStart: () {
                    setState(() {
                      _showHint = true;
                      _navigateAfterHint = true;
                    });
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
                            isSinhala ? 'ඔබේ ප්‍රගතිය' : 'Your Progress',
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
                            isSinhala
                                ? 'මෙම පරීක්ෂණය අදියර 3 කින් සිදු කෙරේ. කරුණාකර නියමිත කාලයේදී පිළිතුරු ලබා දෙන්න.'
                                : 'This assessment consists of 3 timed attempts. Please complete them when they unlock.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.roboto(
                              fontSize: 14,
                              color: AppColors.text.withOpacity(0.7),
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

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
        ),

        // Hint Overlay
        DASS21HintOverlay(
          visible: _showHint,
          isMobile: isMobile,
          onClose: () async {
            if (mounted) setState(() => _showHint = false);
            if (_navigateAfterHint) {
              _navigateAfterHint = false;
              await Future.delayed(const Duration(milliseconds: 250));
              _startQuestionnaire(context, provider);
            }
          },
        ),
      ],
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

    if (!isCompleted) {
      if (attemptNum > 1 &&
          !provider.userAttempts.containsKey(attemptNum - 1)) {
        isLocked = true;
      } else if (unlockDate != null && DateTime.now().isBefore(unlockDate)) {
        isLocked = true;
      }
    }

    String dateStr = isSinhala ? 'නොදනී' : 'TBD';
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

    final statusText = isCompleted
        ? (isSinhala
              ? (isExpanded ? 'ප්‍රතිඵල සඟවන්න' : 'ප්‍රතිඵල පෙන්වන්න')
              : (isExpanded ? 'Hide Results' : 'View Results'))
        : isLocked
        ? (isSinhala ? 'විවෘත වන දිනය: $dateStr' : 'Unlocks on: $dateStr')
        : (isSinhala ? 'දැන් විවෘතයි' : 'Available Now');

    final completedDateText = completedDateStr.isNotEmpty
        ? (isSinhala
              ? 'සම්පූර්ණ කළ දිනය: $completedDateStr'
              : 'Completed on: $completedDateStr')
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
              setState(() {
                _showHint = true;
                _navigateAfterHint = true;
              });
            }
          : null,
      results: Column(
        children: [
          QuestionnaireResultTile(
            title: isSinhala ? 'මානසික අවපීඩනය' : 'Depression',
            scoreText:
                '${provider.getPastScore(attemptNum, 'depression') ?? 0}',
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
            title: isSinhala ? 'කාංසාව' : 'Anxiety',
            scoreText: '${provider.getPastScore(attemptNum, 'anxiety') ?? 0}',
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
            title: isSinhala ? 'පීඩනය' : 'Stress',
            scoreText: '${provider.getPastScore(attemptNum, 'stress') ?? 0}',
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

  void _startQuestionnaire(BuildContext context, DASS21Provider provider) {
    provider.responses = List<int?>.filled(21, null);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DASS21FullQuestionnairePage()),
    ).then((_) {
      if (mounted) provider.loadDASS21Data(context);
    });
  }
}
