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

  @override
  void initState() {
    super.initState();
    _langProvider = Provider.of<LanguageProvider>(context, listen: false);
    _currentLang = _langProvider.currentLang == 'si' ? 'si' : 'en';
    _loadJson(_currentLang);
    _langProvider.addListener(_onLangChanged);

    final provider = Provider.of<MAASProvider>(context, listen: false);
    if (provider.user != null) {
      provider.resetAndLoad(provider.user!, context: context);
    }
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
      await provider.saveToFirebase(context);
      if (!mounted) return;

      final maasScore = provider.latestMAASScore ?? provider.calculateScores();
      final classification =
          provider.latestMAASClassification ??
          provider.classifyScore(maasScore, isSinhala: _currentLang == 'si');

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

  void _showResultDialog(double score, String classification) {
    final isSinhala = _currentLang == 'si';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Stack(
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            child: Container(color: Colors.black.withOpacity(0)),
          ),
          Center(
            child: AlertDialog(
              backgroundColor: AppColors.cardBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              contentPadding: const EdgeInsets.all(24),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isSinhala ? "අවසාන MAAS ලකුණ" : "Final MAAS Score",
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            isSinhala ? 'ලකුණ' : 'Score',
                            style: GoogleFonts.poppins(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            score.toStringAsFixed(2),
                            style: GoogleFonts.roboto(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            isSinhala ? 'වර්ගීකරණය' : 'Classification',
                            style: GoogleFonts.poppins(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                          ),
                          child: Flexible(
                            child: Text(
                              classification,
                              softWrap: true,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
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
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          isSinhala ? "හරි" : "OK",
                          style: GoogleFonts.poppins(
                            color: AppColors.buttonText,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
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
  void dispose() {
    _langProvider.removeListener(_onLangChanged);
    _scrollController.dispose();
    super.dispose();
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
              _currentLang == 'si' ? 'MAAS ප්‍රශ්නාවලිය' : 'MAAS Questionnaire',
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
                      // Progress header
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
                            return Card(
                              color: AppColors.cardBackground,
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 3,
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${qId}. ${q['question']}',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: isMobile ? 15 : 17,
                                        color: AppColors.text,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    LayoutBuilder(
                                      builder: (context, constraints) {
                                        final chipWidth =
                                            (constraints.maxWidth / 3) - 8;
                                        return Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: _options.entries.map((
                                            entry,
                                          ) {
                                            final intVal =
                                                int.tryParse(entry.key) ?? 0;
                                            final selected =
                                                provider.responses[qId - 1] ==
                                                intVal;
                                            return SizedBox(
                                              width: chipWidth.clamp(
                                                70.0,
                                                160.0,
                                              ),
                                              child: ChoiceChip(
                                                label: Text(
                                                  entry.value,
                                                  textAlign: TextAlign.center,
                                                  style: GoogleFonts.roboto(
                                                    fontSize: isMobile
                                                        ? 13
                                                        : 14,
                                                    color: selected
                                                        ? Colors.white
                                                        : AppColors.text,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                selected: selected,
                                                selectedColor:
                                                    AppColors.completed,
                                                backgroundColor:
                                                    AppColors.cardBackground,
                                                checkmarkColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  side: BorderSide(
                                                    color: selected
                                                        ? AppColors.completed
                                                        : AppColors.tileInactive
                                                              .withOpacity(0.5),
                                                    width: selected ? 2 : 1,
                                                  ),
                                                ),
                                                elevation: selected ? 6 : 0,
                                                onSelected: (_) {
                                                  HapticFeedback.lightImpact();
                                                  provider.setAnswer(
                                                    qId,
                                                    intVal,
                                                  );
                                                },
                                              ),
                                            );
                                          }).toList(),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // Navigation buttons with Hint
                      const SizedBox(height: 16),
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
                          if (_pageIndex > 0)
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _submitting
                                    ? null
                                    : () {
                                        setState(() => _pageIndex -= 1);
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
                          if (_pageIndex > 0)
                            const SizedBox(width: 16)
                          else
                            const Expanded(child: SizedBox.shrink()),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _submitting
                                  ? null
                                  : () {
                                      if (!_pageAnswered(
                                        provider,
                                        _pageIndex,
                                      )) {
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
          // Hint overlay
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

        MAASHintOverlay(
          visible: _hintVisible,
          onClose: () => setState(() => _hintVisible = false),
          isMobile: isMobile,
        ),
      ],
    );
  }
}
