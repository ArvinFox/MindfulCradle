import 'dart:convert';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '/constants/colors.dart';
import '../../../providers/maas_provider.dart';
import '/providers/language_provider.dart';
import '../../../utils/maas_hints.dart';
import '../../../providers/achievement_provider.dart';
import '/widgets/questionnaires/questionnaire_question_card.dart';

class MAASFullQuestionnairePage extends StatefulWidget {
  const MAASFullQuestionnairePage({super.key});

  @override
  State<MAASFullQuestionnairePage> createState() =>
      _MAASFullQuestionnairePageState();
}

class _MAASFullQuestionnairePageState extends State<MAASFullQuestionnairePage> {
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _questions = [];
  Map<String, String> _options = {};
  String _currentLang = 'en';
  bool _loading = true;
  bool _submitting = false;
  int _pageIndex = 0;
  final int _perPage = 5;
  late final LanguageProvider _langProvider;
  bool _hintVisible = false;
  bool _attemptedSubmit = false;

  @override
  void initState() {
    super.initState();

    // ENTER IMMERSIVE MODE
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _langProvider = Provider.of<LanguageProvider>(context, listen: false);
    _currentLang = _langProvider.currentLang == 'si' ? 'si' : 'en';
    _loadJson(_currentLang);
    _langProvider.addListener(_onLangChanged);

    final provider = Provider.of<MAASProvider>(context, listen: false);
    if (provider.user != null) {
      provider.resetAndLoad(provider.user!, context: context);
    }
  }

  @override
  void dispose() {
    // EXIT IMMERSIVE MODE
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    _langProvider.removeListener(_onLangChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onLangChanged() {
    final lang = _langProvider.currentLang == 'si' ? 'si' : 'en';
    if (lang != _currentLang) {
      _currentLang = lang;
      _loadJson(_currentLang);
    }
  }

  Future<void> _loadJson(String lang) async {
    setState(() => _loading = true);
    try {
      final path = lang == 'en'
          ? 'languages/maas_en.json'
          : 'languages/maas_si.json';
      final data = json.decode(await rootBundle.loadString(path));
      final allQuestions = List<Map<String, dynamic>>.from(
        data['questions'] ?? [],
      );
      allQuestions.sort((a, b) => (a['id'] as int).compareTo(b['id'] as int));
      setState(() {
        _questions = allQuestions;
        _options = Map<String, String>.from(data['options'] ?? {});
      });
    } catch (e) {
      if (kDebugMode) print('MAAS JSON load error: $e');
      setState(() {
        _questions = [];
        _options = {};
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> _questionsForPage(int pageIndex) {
    final start = pageIndex * _perPage;
    final endNum = (start + _perPage).clamp(0, _questions.length);
    final end = endNum.toInt();
    if (start >= _questions.length) return [];
    return _questions.sublist(start, end);
  }

  bool _pageAnswered(MAASProvider provider, int pageIndex) {
    return _questionsForPage(
      pageIndex,
    ).every((q) => provider.responses[(q['id'] as int) - 1] != null);
  }

  Future<void> _submitAll(MAASProvider provider) async {
    setState(() => _submitting = true);
    try {
      final maasScore = provider.calculateScores();
      final classification = provider.classifyScore(
        maasScore,
        isSinhala: _currentLang == 'si',
      );
      // Save to Firebase
      await provider.saveToFirebase(context);

      if (!mounted) return;

      // Show dialog
      _showResultDialog(maasScore, classification);
    } catch (e) {
      if (kDebugMode) print('Error saving MAAS: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _currentLang == 'si'
                ? 'දෝෂයක් ඇතිවිය. නැවත උත්සාහ කරන්න.'
                : 'Error submitting answers. Try again.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // DIALOG LOGIC
  void _showResultDialog(double score, String classification) {
    final isSinhala = _currentLang == 'si';
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Stack(
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            child: Container(color: Colors.black.withOpacity(0.1)),
          ),
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isSmallScreen ? screenWidth * 0.9 : 380,
                minWidth: screenWidth * 0.8,
              ),
              child: AlertDialog(
                backgroundColor: AppColors.cardBackground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 20,
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isSinhala
                          ? "අවසාන සතිමත් බවේ ලකුණ"
                          : "Final Mindfulness Score",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: isSmallScreen ? 20 : 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Score Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isSinhala ? 'ලකුණ' : 'Score',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text.withOpacity(0.9),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            score.toStringAsFixed(2),
                            style: GoogleFonts.poppins(
                              fontSize: isSmallScreen ? 22 : 26,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Classification Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isSinhala
                                ? 'සතිමත් බවේ වර්ගීකරණය'
                                : 'Level of Mindfulness',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text.withOpacity(0.9),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            classification,
                            textAlign: TextAlign.start,
                            style: GoogleFonts.poppins(
                              fontSize: isSmallScreen ? 17 : 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () {
                          // Get Reference to Achievement Provider before popping
                          final achProvider = Provider.of<AchievementProvider>(
                            context,
                            listen: false,
                          );

                          // Close Dialog
                          Navigator.of(context).pop();

                          // Close Page
                          Navigator.of(context).pop();

                          // Trigger the Pending Dialog on the Start Screen
                          achProvider.showPendingAchievements(context);
                        },
                        child: Text(
                          isSinhala ? "හරි" : "OK",
                          style: GoogleFonts.poppins(
                            color: AppColors.buttonText,
                            fontWeight: FontWeight.w600,
                            fontSize: isSmallScreen ? 15 : 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MAASProvider>(context);
    final isMobile = MediaQuery.of(context).size.width < 600;
    final totalQuestions = _questions.length;
    final totalPages = (totalQuestions / _perPage).ceil();

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              color: Colors.white,
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              _currentLang == 'si'
                  ? 'සතිමත් බව පරීක්ෂාව'
                  : 'Mindfulness Checker',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: isMobile ? 18 : 20,
              ),
            ),
            backgroundColor: AppColors.primary,
            centerTitle: true,
          ),
          body: _loading
              ? Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: Column(
                    children: [
                      // Progress Header
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentLang == 'si'
                                  ? 'ප්‍රශ්න: ${(_pageIndex * _perPage) + 1} - ${((_pageIndex * _perPage + _questionsForPage(_pageIndex).length).clamp(0, totalQuestions)).toInt()} න් $totalQuestions'
                                  : 'Questions: ${(_pageIndex * _perPage) + 1} - ${((_pageIndex * _perPage + _questionsForPage(_pageIndex).length).clamp(0, totalQuestions)).toInt()} of $totalQuestions',
                              style: GoogleFonts.poppins(
                                color: AppColors.text.withOpacity(0.7),
                                fontWeight: FontWeight.w500,
                                fontSize: isMobile ? 14 : 15,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value:
                                    (_pageIndex + 1) /
                                    (totalPages == 0 ? 1 : totalPages),
                                color: AppColors.primary,
                                backgroundColor: AppColors.primary.withOpacity(
                                  0.2,
                                ),
                                minHeight: 8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Questions list
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          physics: const BouncingScrollPhysics(),
                          itemCount: _questionsForPage(_pageIndex).length,
                          itemBuilder: (context, idx) {
                            final q = _questionsForPage(_pageIndex)[idx];
                            final qId = q['id'] as int;
                            final bool isMissing =
                                _attemptedSubmit &&
                                provider.responses[qId - 1] == null;

                            return QuestionnaireQuestionCard(
                              questionId: qId,
                              questionText: q['question'],
                              options: _options,
                              selectedValue: provider.responses[qId - 1],
                              onAnswerSelected: (intVal) {
                                provider.setAnswer(qId, intVal);
                                setState(() => _hintVisible = false);
                              },
                              isMissing: isMissing,
                              isMobile: isMobile,
                              missingText: _currentLang == 'si'
                                  ? '* අනිවාර්යයි'
                                  : '* Required',
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // IMPROVED BUTTON LAYOUT ---
                      Row(
                        children: [
                          FloatingActionButton(
                            mini: true,
                            backgroundColor: AppColors.primary,
                            onPressed: () =>
                                setState(() => _hintVisible = true),
                            elevation: 0,
                            child: const Icon(
                              Icons.help_outline,
                              color: AppColors.buttonText,
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Previous Button (Only show if > Page 0)
                          if (_pageIndex > 0) ...[
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _submitting
                                    ? null
                                    : () {
                                        setState(() {
                                          _pageIndex -= 1;
                                          _attemptedSubmit = false;
                                        });
                                        _scrollToTop();
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.tileInactive,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  _currentLang == 'si' ? 'පෙරට' : 'Previous',
                                  style: GoogleFonts.poppins(
                                    color: AppColors.text,
                                    fontWeight: FontWeight.w600,
                                    fontSize: isMobile ? 15 : 17,
                                  ),
                                ),
                              ),
                            ),
                            // Gap between buttons
                            const SizedBox(width: 16),
                          ] else
                            // Push Next button to right on Page 0 without stretching
                            const Spacer(),

                          // Next / Submit Button
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _submitting
                                  ? null
                                  : () {
                                      if (!_pageAnswered(
                                        provider,
                                        _pageIndex,
                                      )) {
                                        setState(() => _attemptedSubmit = true);
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              _currentLang == 'si'
                                                  ? "කරුණාකර සියලුම ප්‍රශ්නවලට පිළිතුරු ලබා දෙන්න."
                                                  : "Please answer all questions before proceeding.",
                                            ),
                                            backgroundColor:
                                                Colors.orangeAccent,
                                          ),
                                        );
                                        return;
                                      }
                                      setState(() => _attemptedSubmit = false);
                                      if (_pageIndex < totalPages - 1) {
                                        setState(() => _pageIndex += 1);
                                        _scrollToTop();
                                      } else {
                                        _submitAll(provider);
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                _pageIndex < totalPages - 1
                                    ? (_currentLang == 'si' ? 'මීළඟට' : 'Next')
                                    : (_currentLang == 'si'
                                          ? 'ඉදිරිපත් කරන්න'
                                          : 'Submit'),
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: isMobile ? 15 : 17,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
        ),
        MAASHintOverlay(
          visible: _hintVisible,
          isMobile: isMobile,
          onClose: () => setState(() => _hintVisible = false),
        ),
        if (_submitting)
          Container(
            color: AppColors.background,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text(
                    _currentLang == 'si'
                        ? "ඉදිරිපත් කරනවා..."
                        : "Submitting...",
                    style: GoogleFonts.poppins(
                      color: AppColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
