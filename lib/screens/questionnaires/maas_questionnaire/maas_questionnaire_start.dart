import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '/constants/colors.dart';
import '../../../providers/maas_provider.dart';
import '/providers/language_provider.dart';
import 'maas_full_questionnaire.dart';
import 'package:mamamind/utils/maas_hints.dart';
import 'package:mamamind/utils/helpers.dart';
import '/widgets/questionnaires/questionnaire_attempt_card.dart';
import '/widgets/questionnaires/questionnaire_intro_screen.dart';
import '/widgets/questionnaires/questionnaire_marquee_title.dart';
import '/widgets/questionnaires/questionnaire_result_tiles.dart';

class MAASQuestionnaireStartPage extends StatefulWidget {
  const MAASQuestionnaireStartPage({super.key});

  @override
  State<MAASQuestionnaireStartPage> createState() =>
      _MAASQuestionnaireStartPageState();
}

class _MAASQuestionnaireStartPageState
    extends State<MAASQuestionnaireStartPage> {
  bool _initialized = false;

  bool _showHint = false;
  bool _navigateAfterHint = false;

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
    final isSinhala = langProvider.currentLang == 'si';
    final isMobile = MediaQuery.of(context).size.width < 600;

    final titleTextStyle = GoogleFonts.poppins(
      color: Colors.white,
      fontWeight: FontWeight.w600,
      fontSize: 20,
    );

    bool showIntro = !provider.isLoading && provider.userAttempts.isEmpty;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: QuestionnaireMarqueeTitle(
              text: isSinhala ? 'සතිමත් බව පරීක්ෂාව' : 'Mindfulness Checker',
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
                      ? 'සතිමත්බව පරීක්ෂාව (MAAS) වෙත සාදරයෙන් පිළිගනිමු!'
                      : 'Welcome to the Mindfulness Checker (MAAS)',
                  subtitle: isSinhala
                      ? 'මෙම ප්‍රශ්නාවලිය ඔබේ අවධානය සහ වත්මන් අවස්ථාවේ හැඟීම් පිළිබඳ අවබෝධය මැනේ.'
                      : 'This questionnaire measures your awareness and mindfulness level in daily life.',
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

                        // Attempt 1
                        _buildAttemptCard(context, 1, provider, isSinhala),
                        // Attempt 2
                        _buildAttemptCard(context, 2, provider, isSinhala),
                        // Attempt 3
                        _buildAttemptCard(context, 3, provider, isSinhala),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
        ),

        MAASHintOverlay(
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
      results: QuestionnaireResultTile(
        title: isSinhala ? "සතිමත් බ‌වේ වර්ගීකරණය" : "Mindfulness Level",
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

  void _startQuestionnaire(BuildContext context, MAASProvider provider) {
    provider.responses = List<int?>.filled(15, null);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MAASFullQuestionnairePage()),
    ).then((_) {
      if (mounted) provider.loadMAASData(context);
    });
  }
}
