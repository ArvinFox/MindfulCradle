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

  bool _showHint = false;
  bool _navigateAfterHint = false;

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

  // Translation Helper
  String _getSinhalaLabel(String key) {
    switch (key) {
      case 'Autonomy':
        return 'ස්වයං පාලනය';
      case 'Environmental Mastery':
        return 'පරිසරය කළමනාකරණය';
      case 'Personal Growth':
        return 'පුද්ගලික වර්ධනය';
      case 'Positive Relations with Others':
        return 'යහපත් අන්තර් පුද්ගල සබඳතා';
      case 'Purpose in Life':
        return 'ජීවිතයේ අරමුණ';
      case 'Self-Acceptance':
        return 'ස්වයං පිළිගැනීම';
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
      color: Colors.white,
      fontWeight: FontWeight.w600,
      fontSize: 20,
    );

    final hasData =
        provider.unlockDates.isNotEmpty || provider.userAttempts.isNotEmpty;
    final canStart = hasInternet && hasData && !provider.isLoading;
    final helperText = _helperText(isSinhala, hasInternet, hasData);
    bool showIntro = !provider.isLoading && provider.userAttempts.isEmpty;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: QuestionnaireMarqueeTitle(
              text: isSinhala
                  ? 'මානසික සොඛ්‍ය සහ සතුට සොඛ්‍ය පරීක්ෂාව'
                  : 'Mental Health & Happiness Checker',
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
                      ? 'මානසික සොඛ්‍ය සහ සතුට සොඛ්‍ය පරීක්ෂාව (PWS-18) වෙත සාදරයෙන් පිළිගනිමු!'
                      : 'Welcome to Psychological Well-Being Scale (PWS-18)',
                  subtitle: isSinhala
                      ? 'මෙම ප්‍රශ්නාවලිය ඔබේ සතුට, සොඛ්‍යය සහ මනෝවිද්‍යාත්මක ස්වභාවය පිළිබඳ විශ්ලේෂණයක් ලබා දේ.'
                      : 'This questionnaire provides insights into your psychological well-being and personal growth.',
                  buttonText: isSinhala
                      ? 'ප්‍රතිචාර ආරම්භ කරන්න'
                      : 'Start Feedback',
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
                    setState(() {
                      _showHint = true;
                      _navigateAfterHint = true;
                    });
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

        PWS18HintOverlay(
          visible: _showHint,
          isMobile: isMobile,
          onClose: () async {
            if (mounted) setState(() => _showHint = false);
            if (_navigateAfterHint) {
              _navigateAfterHint = false;
              await Future.delayed(const Duration(milliseconds: 250));
              _startQuestionnaire(
                context,
                provider,
                hasInternet,
                hasData,
                isSinhala,
              );
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
    PWS18Provider provider,
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
              setState(() {
                _showHint = true;
                _navigateAfterHint = true;
              });
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
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 3 / 2,
      children: provider.subscales.keys.map((key) {
        final score = scores[key];
        final displayTitle = isSinhala ? _getSinhalaLabel(key) : key;

        return QuestionnaireCategoryTile(
          title: displayTitle,
          score: score,
          tileColor: score != null
              ? scoreToColorPWS18(score)
              : AppColors.tileInactive,
        );
      }).toList(),
    );
  }

  void _startQuestionnaire(
    BuildContext context,
    PWS18Provider provider,
    bool hasInternet,
    bool hasData,
    bool isSinhala,
  ) {
    if (!hasInternet || !hasData) {
      _showStartBlockedMessage(context, isSinhala, hasInternet, hasData);
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

  String? _helperText(bool isSinhala, bool hasInternet, bool hasData) {
    if (!hasInternet) {
      return isSinhala
          ? 'අන්තර්ජාල සම්බන්ධතාවයක් නොමැත'
          : 'No internet connection';
    }
    if (!hasData) {
      return isSinhala
          ? 'දත්ත ලබාගත නොහැක. කරුණාකර පසුව උත්සාහ කරන්න.'
          : 'Data unavailable. Please try again later.';
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
        ? (isSinhala
              ? 'අන්තර්ජාල සම්බන්ධතාවයක් නොමැත'
              : 'No internet connection')
        : (isSinhala
              ? 'දත්ත ලබාගත නොහැක. කරුණාකර පසුව උත්සාහ කරන්න.'
              : 'Data unavailable. Please try again later.');

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade600),
    );
  }
}
