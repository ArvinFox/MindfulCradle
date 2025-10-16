import 'package:flutter/material.dart';
import 'package:mamamind/utils/dass21_hints.dart';
import 'package:provider/provider.dart';
import 'package:marquee/marquee.dart';
import 'package:google_fonts/google_fonts.dart';
import '/constants/colors.dart';
import '../../../providers/dass21_provider.dart';
import '/providers/language_provider.dart';
import '/utils/custom_alert.dart';
import 'dass21_full_questionnaire.dart';
import '/utils/helpers.dart';

class DASS21QuestionnaireStartPage extends StatefulWidget {
  const DASS21QuestionnaireStartPage({super.key});

  @override
  State<DASS21QuestionnaireStartPage> createState() =>
      _DASS21QuestionnaireStartPageState();
}

class _DASS21QuestionnaireStartPageState
    extends State<DASS21QuestionnaireStartPage> {
  bool _initialized = false;
  bool _showHint = false;
  bool _navigateAfterHint = false;
  bool _pauseMarquee = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final provider = Provider.of<DASS21Provider>(context, listen: false);
      provider.reset();
      provider.loadLatest(context).then((_) {
        if (mounted) setState(() {});
      });
      _initialized = true;
    }
  }

  Future<bool> _confirmEdit(bool isSinhala) async {
    final edit = await CustomConfirmationDialog.show(
      context: context,
      title: isSinhala ? 'පිළිතුරු සංස්කරණය කරන්න' : 'Edit Responses?',
      message: isSinhala
          ? 'ඔබට ඔබේ පිළිතුරු සංස්කරණය කිරීමට අවශ්‍යද?'
          : 'Do you want to edit your responses?',
      confirmText: isSinhala ? 'ඔව්' : 'Yes',
      cancelText: isSinhala ? 'නැහැ' : 'No',
    );
    return edit;
  }

  Widget _buildSubscaleTile(
    String title,
    bool answered,
    int? score,
    String classification,
  ) {
    final tileColor = answered && score != null
        ? scoreToColorDASS21(title, score)
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
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          if (score != null) ...[
            const SizedBox(height: 8),
            Text(
              "$score",
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              classification,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _openQuestionnaireAfterHint() {
    if (!mounted) return;
    final page = const DASS21FullQuestionnairePage();
    Navigator.push(context, MaterialPageRoute(builder: (_) => page)).then((_) {
      Provider.of<DASS21Provider>(context, listen: false).loadLatest(context);
    });
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

    if (provider.isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: _buildMarqueeTitle(isSinhala, titleTextStyle),
          centerTitle: true,
          backgroundColor: AppColors.primary,
        ),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      );
    }

    // --- Subscale completion checks ---
    bool depressionDone = provider.depressionQ.every(
      (q) => provider.responses[q - 1] != null,
    );
    bool anxietyDone = provider.anxietyQ.every(
      (q) => provider.responses[q - 1] != null,
    );
    bool stressDone = provider.stressQ.every(
      (q) => provider.responses[q - 1] != null,
    );

    final allCompleted = depressionDone && anxietyDone && stressDone;

    // --- Safe conversion ---
    final scores = allCompleted
        ? Map<String, int>.from(provider.calculateScores())
        : <String, int>{};

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: _buildMarqueeTitle(isSinhala, titleTextStyle),
            centerTitle: true,
            backgroundColor: AppColors.primary,
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
          body: !allCompleted
              ? _buildIntroScreen(isSinhala, isMobile)
              : _buildResultsScreen(
                  isSinhala,
                  provider,
                  depressionDone,
                  anxietyDone,
                  stressDone,
                  scores,
                  isMobile,
                ),
        ),
        DASS21HintOverlay(
          visible: _showHint,
          isMobile: isMobile,
          onClose: () async {
            if (mounted) setState(() => _showHint = false);
            if (_navigateAfterHint) {
              _navigateAfterHint = false;
              await Future.delayed(const Duration(milliseconds: 250));
              _openQuestionnaireAfterHint();
            }
          },
        ),
      ],
    );
  }

  Widget _buildMarqueeTitle(bool isSinhala, TextStyle style) {
    final text = isSinhala
        ? 'හැඟීම් පරික්ෂාව'
        : 'Feelings Checker';

    return GestureDetector(
      onTap: () => setState(() => _pauseMarquee = !_pauseMarquee),
      child: SizedBox(
        height: 30,
        child: Marquee(
          text: text,
          style: style,
          scrollAxis: Axis.horizontal,
          blankSpace: 60,
          velocity: _pauseMarquee ? 0.0 : 30.0,
          pauseAfterRound: const Duration(seconds: 1),
          startPadding: 10.0,
          accelerationDuration: const Duration(seconds: 1),
          accelerationCurve: Curves.linear,
          decelerationDuration: const Duration(milliseconds: 500),
          decelerationCurve: Curves.easeOut,
        ),
      ),
    );
  }

  Widget _buildIntroScreen(bool isSinhala, bool isMobile) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isSinhala
                  ? 'හැඟීම් පරීක්ෂාව (DASS-21) වෙත සාදරයෙන් පිළිගනිමු!'
                  : 'Welcome to Feelings Checker (DASS-21) Questionnaire',
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
                  ? 'මෙම ප්‍රශ්නාවලිය ඔබේ මානසික අවපීඩන, කාංසාව, පීඩනය මට්ටම් පිළිබඳ විශ්ලේෂණයක් ලබා දේ.'
                  : 'This questionnaire provides insights into your Depression, Anxiety, Stress levels.',
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

  Widget _buildResultsScreen(
    bool isSinhala,
    DASS21Provider provider,
    bool depressionDone,
    bool anxietyDone,
    bool stressDone,
    Map<String, int> scores,
    bool isMobile,
  ) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 18),
          Text(
            isSinhala
                ? 'ඔබ කලින් පිළිතුරු වෙනස් කිරීමට අවශ්‍ය නම් පහත බොත්තම භාවිතා කරන්න'
                : 'If you want to edit your previous responses, use the button below.',
            textAlign: TextAlign.center,
            style: GoogleFonts.roboto(
              fontSize: isMobile ? 12 : 14,
              fontWeight: FontWeight.w400,
              color: AppColors.text.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 12),
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
              onPressed: () async {
                final edit = await _confirmEdit(isSinhala);
                if (!edit) return;
                setState(() {
                  _showHint = true;
                  _navigateAfterHint = true;
                });
              },
              child: Text(
                isSinhala ? 'පිළිතුරු සංස්කරණය කරන්න' : 'Edit Responses',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.buttonText,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              isSinhala ? 'අවසන් ප්‍රතිඵල' : 'Final Results',
              style: GoogleFonts.poppins(
                fontSize: isMobile ? 20 : 22,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 3 / 2,
              children: [
                _buildSubscaleTile(
                  isSinhala ? 'මානසික අවපීඩනය' : 'Depression',
                  depressionDone,
                  scores['depression'],
                  provider.classifyDepression(scores['depression'] ?? 0, isSinhala: isSinhala),
                ),
                _buildSubscaleTile(
                  isSinhala ? 'කාංසාව' : 'Anxiety',
                  anxietyDone,
                  scores['anxiety'],
                  provider.classifyAnxiety(scores['anxiety'] ?? 0, isSinhala: isSinhala),
                ),
                _buildSubscaleTile(
                  isSinhala ? 'පීඩනය' : 'Stress',
                  stressDone,
                  scores['stress'],
                  provider.classifyStress(scores['stress'] ?? 0, isSinhala: isSinhala),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
