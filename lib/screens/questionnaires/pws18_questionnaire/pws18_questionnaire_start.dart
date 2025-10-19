import 'package:flutter/material.dart';
import 'package:mamamind/utils/custom_alert.dart';
import 'package:provider/provider.dart';
import 'package:marquee/marquee.dart';
import '/constants/colors.dart';
import '/providers/pws18_provider.dart';
import '/providers/language_provider.dart';
import 'pws18_full_questionnaire.dart';
import '/utils/helpers.dart';
import '/utils/pws18_hints.dart';
import 'package:google_fonts/google_fonts.dart';

class PWS18QuestionnaireStartPage extends StatefulWidget {
  const PWS18QuestionnaireStartPage({super.key});

  @override
  State<PWS18QuestionnaireStartPage> createState() =>
      _PWS18QuestionnaireStartPageState();
}

class _PWS18QuestionnaireStartPageState
    extends State<PWS18QuestionnaireStartPage> {
  bool _initialized = false;
  bool _showHint = false;
  bool _navigateAfterHint = false;
  bool _pauseMarquee = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final provider = Provider.of<PWS18Provider>(context, listen: false);
      provider.reset();
      provider.loadLatest(context).then((_) {
        if (mounted) setState(() {});
      });
      _initialized = true;
    }
  }

  // Future<bool> _confirmEdit(bool isSinhala) async {
  //   final edit = await CustomConfirmationDialog.show(
  //     context: context,
  //     title: isSinhala ? 'පිළිතුරු සංස්කරණය කරන්න' : 'Edit Responses?',
  //     message: isSinhala
  //         ? 'ඔබට ඔබේ පිළිතුරු සංස්කරණය කිරීමට අවශ්‍යද?'
  //         : 'Do you want to edit your responses?',
  //     confirmText: isSinhala ? 'ඔව්' : 'Yes',
  //     cancelText: isSinhala ? 'නැහැ' : 'No',
  //   );
  //   return edit;
  // }

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

  void _openQuestionnaireAfterHint() {
    if (!mounted) return;
    final provider = Provider.of<PWS18Provider>(context, listen: false);
    final page = const PWS18FullQuestionnairePage();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    ).then((_) => provider.loadLatest(context));
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

    Map<String, bool> answeredMap = {};
    for (var category in provider.subscales.keys) {
      answeredMap[category] = provider.subscales[category]!.every(
        (qId) => provider.responses[qId - 1] != null,
      );
    }

    final allCompleted = answeredMap.values.isNotEmpty
        ? answeredMap.values.every((v) => v)
        : false;

    Map<String, double> subscaleScores = {};
    if (allCompleted) subscaleScores = provider.calculateScores();

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
                  answeredMap,
                  subscaleScores,
                  isMobile,
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
              _openQuestionnaireAfterHint();
            }
          },
        ),
      ],
    );
  }

  Widget _buildMarqueeTitle(bool isSinhala, TextStyle style) {
    final text = isSinhala
        ? 'මානසික සතුට සහ සෞඛ්‍ය පරීක්ෂාව'
        : 'Mental Health & Happiness Check';

    return GestureDetector(
      onTap: () => setState(() => _pauseMarquee = !_pauseMarquee),
      child: SizedBox(
        height: 30,
        child: Marquee(
          text: text,
          style: appBarTextStyle,
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
                  ? 'මානසික සෞඛ්‍ය මට්ටම් පරීක්ෂාව (PWS-18) වෙත සාදරයෙන් පිළිගනිමු!'
                  : 'Welcome to Psychological Well-Being Scale (PWS-18) Questionnaire',
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

  Widget _buildResultsScreen(
    bool isSinhala,
    PWS18Provider provider,
    Map<String, bool> answeredMap,
    Map<String, double> subscaleScores,
    bool isMobile,
  ) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // const SizedBox(height: 18),
          // Text(
          //   isSinhala
          //       ? 'ඔබ කලින් පිළිතුරු වෙනස් කිරීමට අවශ්‍ය නම් පහත බොත්තම භාවිතා කරන්න'
          //       : 'If you want to edit your previous responses, use the button below.',
          //   textAlign: TextAlign.center,
          //   style: GoogleFonts.roboto(
          //     fontSize: isMobile ? 12 : 14,
          //     fontWeight: FontWeight.w400,
          //     color: AppColors.text.withOpacity(0.8),
          //   ),
          // ),
          // const SizedBox(height: 12),
          // SizedBox(
          //   width: double.infinity,
          //   child: ElevatedButton(
          //     style: ElevatedButton.styleFrom(
          //       backgroundColor: AppColors.primary,
          //       padding: const EdgeInsets.symmetric(vertical: 14),
          //       shape: RoundedRectangleBorder(
          //         borderRadius: BorderRadius.circular(12),
          //       ),
          //     ),
          //     onPressed: () async {
          //       final edit = await _confirmEdit(isSinhala);
          //       if (!edit) return;
          //       setState(() {
          //         _showHint = true;
          //         _navigateAfterHint = true;
          //       });
          //     },
          //     child: Text(
          //       isSinhala ? 'පිළිතුරු සංස්කරණය කරන්න' : 'Edit Responses',
          //       style: GoogleFonts.poppins(
          //         fontSize: 16,
          //         fontWeight: FontWeight.w600,
          //         color: AppColors.buttonText,
          //       ),
          //     ),
          //   ),
          // ),
          // const SizedBox(height: 20),
          Text(
            isSinhala
                ? 'අවධානය පරීක්ෂණයේ ඔබ‌ෙග‌ේ අවසාන ප්‍රතිඵල ලකුණු පහත දැක්වේ.'
                : 'Your final results for the Mindfulness Checker are shown below',
            textAlign: TextAlign.center,
            style: GoogleFonts.roboto(
              fontSize: isMobile ? 16 : 20,
              fontWeight: FontWeight.w400,
              color: AppColors.text.withOpacity(0.8),
            ),
          ),
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
          // Completed Date
          if (provider.completedAt != null)
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                isSinhala
                    ? 'අවසන් පිළිතුරු දිනය: ${formatDate(provider.completedAt!)}'
                    : 'Completed on: ${formatDate(provider.completedAt!)}',
                style: GoogleFonts.roboto(
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.w400,
                  color: AppColors.text.withOpacity(0.7),
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
              children: provider.subscales.keys.map((key) {
                final answered = answeredMap[key] ?? false;
                final score = subscaleScores[key];
                return _buildCategoryTile(
                  key + subscaleSuffix(key, isSinhala),
                  answered,
                  score,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String subscaleSuffix(String key, bool isSinhala) => '';
}
