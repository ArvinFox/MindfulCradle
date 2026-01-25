import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:marquee/marquee.dart';
import '/constants/colors.dart';
import '/providers/pws18_provider.dart';
import '/providers/language_provider.dart';
import 'pws18_full_questionnaire.dart';
import '/utils/helpers.dart';
import '/utils/pws18_hints.dart';

class PWS18QuestionnaireStartPage extends StatefulWidget {
  const PWS18QuestionnaireStartPage({super.key});

  @override
  State<PWS18QuestionnaireStartPage> createState() =>
      _PWS18QuestionnaireStartPageState();
}

class _PWS18QuestionnaireStartPageState
    extends State<PWS18QuestionnaireStartPage> {
  bool _initialized = false;
  bool _pauseMarquee = false;

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
            title: _buildMarqueeTitle(isSinhala, titleTextStyle),
            centerTitle: true,
            backgroundColor: AppColors.primary,
            automaticallyImplyLeading:
                false,
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
              ? _buildIntroScreen(isSinhala, isMobile)
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
              _startQuestionnaire(context, provider);
            }
          },
        ),
      ],
    );
  }

  // Intro Screen
  Widget _buildIntroScreen(bool isSinhala, bool isMobile) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isSinhala
                  ? 'මානසික සෞඛ්‍ය සහ සතුට සෞඛ්‍ය පරීක්ෂාව (PWS-18) වෙත සාදරයෙන් පිළිගනිමු!'
                  : 'Welcome to Psychological Well-Being Scale (PWS-18)',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: isMobile ? 20 : 22,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isSinhala
                  ? 'මෙම ප්‍රශ්නාවලිය ඔබේ සතුට, සෞඛ්‍යය සහ මනෝවිද්‍යාත්මක ස්වභාවය පිළිබඳ විශ්ලේෂණයක් ලබා දේ.'
                  : 'This questionnaire provides insights into your psychological well-being and personal growth.',
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                fontSize: isMobile ? 14 : 16,
                fontWeight: FontWeight.w400,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _showHint = true;
                    _navigateAfterHint = true;
                  });
                },
                child: Text(
                  isSinhala ? 'ප්‍රතිචාර ආරම්භ කරන්න' : 'Start Feedback',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.buttonText,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarqueeTitle(bool isSinhala, TextStyle style) {
    final text = isSinhala
        ? 'මානසික සෞඛ්‍ය සහ සතුට සෞඛ්‍ය පරීක්ෂාව'
        : 'Mental Health & Happiness Checker';

    return GestureDetector(
      onTap: () => setState(() => _pauseMarquee = !_pauseMarquee),
      child: SizedBox(
        height: 30,
        child: Marquee(
          text: text,
          style: style,
          scrollAxis: Axis.horizontal,
          blankSpace: 60,
          velocity: _pauseMarquee ? 0.001 : 30.0,
          pauseAfterRound: const Duration(seconds: 1),
          startPadding: 10.0,
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

    if (!isCompleted) {
      if (attemptNum > 1 &&
          !provider.userAttempts.containsKey(attemptNum - 1)) {
        isLocked = true;
      } else if (unlockDate != null && DateTime.now().isBefore(unlockDate)) {
        isLocked = true;
      }
    }

    final cardBg = isCompleted
        ? AppColors.completed.withOpacity(0.05)
        : AppColors.cardBackground;
    final borderColor = isCompleted
        ? AppColors.completed.withOpacity(0.5)
        : Colors.grey.withOpacity(0.2);

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

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: isCompleted
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
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppColors.completed
                          : (isLocked ? Colors.grey[400] : AppColors.primary),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isCompleted
                          ? Icons.check
                          : (isLocked
                                ? Icons.lock_outline
                                : Icons.play_arrow_rounded),
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isSinhala
                              ? 'අදියර $attemptNum'
                              : 'Attempt $attemptNum',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isCompleted
                              ? (isSinhala
                                    ? (isExpanded
                                          ? 'ප්‍රතිඵල සඟවන්න'
                                          : 'ප්‍රතිඵල පෙන්වන්න')
                                    : (isExpanded
                                          ? 'Hide Results'
                                          : 'View Results'))
                              : isLocked
                              ? (isSinhala
                                    ? 'විවෘත වන දිනය: $dateStr'
                                    : 'Unlocks on: $dateStr')
                              : (isSinhala ? 'දැන් විවෘතයි' : 'Available Now'),
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            color: isCompleted
                                ? AppColors.completed
                                : (isLocked ? Colors.grey : AppColors.primary),
                            fontWeight: isCompleted || !isLocked
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isCompleted)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: AppColors.text.withOpacity(0.6),
                        size: 32,
                      ),
                    )
                  else if (!isLocked)
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _showHint = true;
                          _navigateAfterHint = true;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      child: Text(
                        isSinhala ? 'අරඹන්න' : 'Start',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Results
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: (isCompleted && isExpanded)
                ? Column(
                    children: [
                      Container(height: 1, color: borderColor),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            if (completedDateStr.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: Text(
                                  isSinhala
                                      ? 'සම්පූර්ණ කළ දිනය: $completedDateStr'
                                      : 'Completed on: $completedDateStr',
                                  style: GoogleFonts.roboto(
                                    fontSize: 14,
                                    color: AppColors.text.withOpacity(0.6),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            _buildResultGrid(attemptNum, provider, isSinhala),
                          ],
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
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

        return _buildCategoryTile(displayTitle, true, score);
      }).toList(),
    );
  }

  Widget _buildCategoryTile(String title, bool answered, double? score) {
    final tileColor = answered && score != null
        ? scoreToColorPWS18(score)
        : AppColors.tileInactive;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: tileColor, width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          if (score != null) ...[
            const SizedBox(height: 8),
            Text(
              score.toStringAsFixed(2),
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _startQuestionnaire(BuildContext context, PWS18Provider provider) {
    provider.responses = List<int?>.filled(18, null);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PWS18FullQuestionnairePage()),
    ).then((_) {
      if (mounted) provider.loadPWS18Data(context);
    });
  }
}
