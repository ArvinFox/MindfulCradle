import 'package:flutter/material.dart';
import 'package:mamamind/utils/helpers.dart';
import 'package:mamamind/utils/maas_hints.dart';
import 'package:provider/provider.dart';
import 'package:marquee/marquee.dart';
import 'package:google_fonts/google_fonts.dart';
import '/constants/colors.dart';
import '../../../providers/maas_provider.dart';
import '/providers/language_provider.dart';
// import '/utils/custom_alert.dart';
import 'maas_full_questionnaire.dart';

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
  bool _pauseMarquee = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final provider = Provider.of<MAASProvider>(context, listen: false);
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

  Widget _buildScoreTile(double? score, String classification) {
    final tileColor = score != null
        ? scoreToColorMAAS(score)
        : AppColors.tileInactive;
    final screenWidth = MediaQuery.of(context).size.width;

    // get current language
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final isSinhala = langProvider.currentLang == 'si';

    // scale fonts based on screen width
    double titleFont = screenWidth < 600 ? 18 : 18;
    double scoreFont = screenWidth < 600 ? 18 : 28;
    double classFont = screenWidth < 600 ? 15 : 16;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isSinhala ? "සතිමත් බ‌වේ වර්ගීකරණය" : "Mindfulness Level",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: titleFont,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            score != null ? score.toStringAsFixed(2) : "-",
            style: GoogleFonts.poppins(
              fontSize: scoreFont,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            classification.isNotEmpty ? classification : "-",
            style: GoogleFonts.poppins(
              fontSize: classFont,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _openQuestionnaireAfterHint() {
    if (!mounted) return;
    final page = const MAASFullQuestionnairePage();
    Navigator.push(context, MaterialPageRoute(builder: (_) => page)).then((_) {
      Provider.of<MAASProvider>(context, listen: false).loadLatest(context);
    });
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

    final allCompleted = provider.responses.every(
      (response) => response != null,
    );

    final score = allCompleted ? provider.calculateScores() : null;
    final classification = score != null
        ? provider.classifyScore(score, isSinhala: isSinhala)
        : '';

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
                  score!,
                  classification,
                  isMobile,
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
              _openQuestionnaireAfterHint();
            }
          },
        ),
      ],
    );
  }

  Widget _buildMarqueeTitle(bool isSinhala, TextStyle style) {
    final text = isSinhala ? 'සතිමත් බව පරීක්ෂාව' : 'Mindfulness Checker';

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

  Widget _buildIntroScreen(bool isSinhala, bool isMobile) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isSinhala
                  ? 'සතිමත්බව පරීක්ෂාව (MAAS) වෙත සාදරයෙන් පිළිගනිමු!'
                  : 'Welcome to the Mindfulness Checker (MAAS)',
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
                  ? 'මෙම ප්‍රශ්නාවලිය ඔබේ අවධානය සහ වත්මන් අවස්ථාවේ හැඟීම් පිළිබඳ අවබෝධය මැනේ.'
                  : 'This questionnaire measures your awareness and mindfulness level in daily life.',
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                fontSize: isMobile ? 14 : 16,
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
    MAASProvider provider,
    double score,
    String classification,
    bool isMobile,
  ) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // const SizedBox(height: 18),
          // Text(
          //   isSinhala
          //       ? 'ඔබ කලින් පිළිතුරු වෙනස් කිරීමට අවශ්‍ය නම් පහත බොත්තම භාවිතා කරන්න'
          //       : 'If you want to edit your previous responses, use the button below.',
          //   textAlign: TextAlign.center,
          //   style: GoogleFonts.roboto(
          //     fontSize: isMobile ? 12 : 14,
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
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              isSinhala ? 'අවසන් ප්‍රතිඵල' : 'Final Result',
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
          SizedBox(
            width: double.infinity,
            child: _buildScoreTile(score, classification),
          ),
        ],
      ),
    );
  }
}
