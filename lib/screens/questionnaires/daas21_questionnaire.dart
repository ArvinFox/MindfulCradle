import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mamamind/constants/colors.dart';
import 'package:provider/provider.dart';
import '/providers/daas21_provider.dart';
import '/providers/language_provider.dart';

class DAAS21Page extends StatefulWidget {
  const DAAS21Page({super.key});

  @override
  State<DAAS21Page> createState() => _DAAS21PageState();
}

class _DAAS21PageState extends State<DAAS21Page> {
  int _currentPage = 0;
  bool _started = false;
  List<Map<String, dynamic>> _questions = [];
  Map<String, String> _options = {};
  String _currentLang = '';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    _currentLang = langProvider.currentLang;
    _loadJson(_currentLang);

    langProvider.addListener(() {
      if (_currentLang != langProvider.currentLang) {
        _currentLang = langProvider.currentLang;
        _loadJson(_currentLang);
      }
    });
  }

  Future<void> _loadJson(String lang) async {
    try {
      final path = lang == 'en'
          ? 'languages/daas21_en.json'
          : 'languages/daas21_si.json';

      final jsonStr = await rootBundle.loadString(path);
      final data = json.decode(jsonStr);

      setState(() {
        _questions = List<Map<String, dynamic>>.from(data['questions']);
        _options = Map<String, String>.from(data['options']);
      });
    } catch (e) {
      if (kDebugMode) print("DAAS JSON load error: $e");
    }
  }

  bool pageComplete(int pageIndex, DAAS21Provider provider) {
    int start = pageIndex * 7;
    int end = start + 7;
    for (int i = start; i < end; i++) {
      if (i >= provider.responses.length) return false;
      if (provider.responses[i] == null) return false;
    }
    return true;
  }

  Future<bool> _onWillPop() async {
    if (_currentPage > 0) {
      setState(() => _currentPage--);
      _scrollToTop();
      return false;
    }
    return true;
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildScoreRow(String title, int score) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 16)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "$score",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroScreen(LanguageProvider langProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              langProvider.currentLang == 'en'
                  ? "Welcome to DAAS-21 Feedback"
                  : "DAAS-21 ප්‍රතිචාර වෙත ඔබ සාදරයෙන් පිළිගනිමු",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              langProvider.currentLang == 'en'
                  ? "This feedback helps you understand your levels of depression, anxiety, and stress. Answer honestly to get accurate scores."
                  : "මෙම ප්‍රතිචාරය ඔබේ අවමෝහය, උදෘතය සහ දැඩි සිරිත මට්ටම් වටහා ගැනීමට උපකාරී වේ. නිවැරදි පිළිතුරු ලබාදීමට අවංකව පිළිතුරු දෙන්න.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  setState(() => _started = true);
                  _scrollToTop();
                },
                child: Text(
                  langProvider.currentLang == 'en'
                      ? "Start Feedback"
                      : "ප්‍රතිචාර ආරම්භ කරන්න",
                  style: const TextStyle(
                    fontSize: 16,
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

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DAAS21Provider>(context);
    final langProvider = Provider.of<LanguageProvider>(context);
    final totalPages = (_questions.length / 7).ceil();
    final isMobile = MediaQuery.of(context).size.width < 600;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            langProvider.currentLang == 'en'
                ? 'DAAS-21 Feedback'
                : 'DAAS-21 ප්‍රතිචාර',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: AppColors.primary,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: _questions.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : !_started
                ? _buildIntroScreen(langProvider)
                : Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        // Progress bar + Page counter
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            children: [
                              LinearProgressIndicator(
                                value: (_currentPage + 1) / totalPages,
                                backgroundColor:
                                    AppColors.accent.withOpacity(0.3),
                                color: AppColors.primary,
                                minHeight: 8,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                langProvider.currentLang == 'en'
                                    ? "Page ${_currentPage + 1} of $totalPages"
                                    : "පිටුව ${_currentPage + 1} / $totalPages",
                                style: TextStyle(
                                  color: AppColors.text,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            controller: _scrollController,
                            physics: const BouncingScrollPhysics(),
                            itemCount: 7,
                            itemBuilder: (context, index) {
                              int qIndex = _currentPage * 7 + index;
                              if (qIndex >= _questions.length)
                                return const SizedBox();

                              final q = _questions[qIndex];
                              return Card(
                                color: AppColors.cardBackground,
                                margin:
                                    const EdgeInsets.symmetric(vertical: 6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 3,
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${qIndex + 1}. ${q['question']}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: isMobile ? 14 : 16,
                                          color: AppColors.text,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      ..._options.entries.map(
                                        (entry) => RadioListTile<int>(
                                          value: int.parse(entry.key),
                                          groupValue:
                                              provider.responses[qIndex],
                                          title: Text(
                                            entry.value,
                                            style: TextStyle(
                                              fontSize: isMobile ? 13 : 15,
                                              color: AppColors.text,
                                            ),
                                          ),
                                          onChanged: (val) {
                                            if (val != null) {
                                              provider.setAnswer(
                                                  qIndex + 1, val);
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (_currentPage > 0)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.buttonPrevBack,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () {
                                      setState(() => _currentPage--);
                                      _scrollToTop();
                                    },
                                    child: Text(
                                      langProvider.currentLang == 'en'
                                          ? 'Previous'
                                          : 'පෙර පිටුව',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: AppColors.buttonText,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () async {
                                    if (!pageComplete(_currentPage, provider)) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            langProvider.currentLang == 'en'
                                                ? 'Please answer all questions on this page'
                                                : 'කරුණාකර මෙම පිටුවේ සියලු ප්‍රශ්න වලට පිළිතුරු දක්වන්න',
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    if (_currentPage < totalPages - 1) {
                                      setState(() => _currentPage++);
                                      _scrollToTop();
                                    } else {
                                      try {
                                        await provider.saveToFirebase(context);
                                        final scores =
                                            provider.calculateScores();

                                        showDialog(
                                          context: context,
                                          barrierDismissible: false,
                                          builder: (_) => Center(
                                            child: SingleChildScrollView(
                                              child: AlertDialog(
                                                backgroundColor:
                                                    AppColors.background,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                contentPadding:
                                                    const EdgeInsets.all(24),
                                                content: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      langProvider.currentLang ==
                                                              'en'
                                                          ? "DAAS-21 Results"
                                                          : "DAAS-21 ප්‍රතිඵල",
                                                      style: const TextStyle(
                                                        fontSize: 22,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: AppColors.primary,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 20),
                                                    _buildScoreRow(
                                                      langProvider.currentLang ==
                                                              'en'
                                                          ? "Depression"
                                                          : "අවමෝහය",
                                                      scores['depression'] ?? 0,
                                                    ),
                                                    _buildScoreRow(
                                                      langProvider.currentLang ==
                                                              'en'
                                                          ? "Anxiety"
                                                          : "උදෘතය",
                                                      scores['anxiety'] ?? 0,
                                                    ),
                                                    _buildScoreRow(
                                                      langProvider.currentLang ==
                                                              'en'
                                                          ? "Stress"
                                                          : "දැඩි සිරිත",
                                                      scores['stress'] ?? 0,
                                                    ),
                                                    const SizedBox(height: 24),
                                                    SizedBox(
                                                      width: double.infinity,
                                                      child: ElevatedButton(
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          backgroundColor:
                                                              AppColors.primary,
                                                          padding:
                                                              const EdgeInsets
                                                                      .symmetric(
                                                                  vertical: 14),
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                      12,
                                                                    ),
                                                          ),
                                                        ),
                                                        onPressed: () {
                                                          provider.reset();
                                                          setState(() {
                                                            _currentPage = 0;
                                                            _started = false;
                                                          });
                                                          Navigator.pop(context);
                                                          _scrollToTop();
                                                        },
                                                        child: Text(
                                                          langProvider.currentLang ==
                                                                  'en'
                                                              ? "OK"
                                                              : "හරි",
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 16,
                                                            color: AppColors
                                                                .buttonText,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      } catch (e) {
                                        if (kDebugMode)
                                          print("Error saving DAAS21: $e");
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              langProvider.currentLang == 'en'
                                                  ? "Error saving responses. Try again."
                                                  : "පිළිතුරු සුරැකිමේදී දෝෂයක්. නැවත උත්සාහ කරන්න.",
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  child: Text(
                                    _currentPage < totalPages - 1
                                        ? (langProvider.currentLang == 'en'
                                                ? 'Next'
                                                : 'ඊළඟ')
                                        : (langProvider.currentLang == 'en'
                                                ? 'Submit'
                                                : 'සබ්මිට්'),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: AppColors.buttonText,
                                    ),
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
    );
  }
}
