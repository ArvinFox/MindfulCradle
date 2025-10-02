import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mamamind/constants/colors.dart';
import 'package:provider/provider.dart';
import '/providers/maas_provider.dart';
import '/providers/language_provider.dart';

class MAASPage extends StatefulWidget {
  const MAASPage({super.key});

  @override
  State<MAASPage> createState() => _MAASPageState();
}

class _MAASPageState extends State<MAASPage> {
  int _currentPage = 0;
  bool _started = false;
  bool _isSubmitting = false;
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

    // Listen for language changes
    langProvider.addListener(() {
      if (_currentLang != langProvider.currentLang) {
        _currentLang = langProvider.currentLang;
        _loadJson(_currentLang);
      }
    });

    // Load latest MAAS score from provider
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<MAASProvider>(context, listen: false);
      await provider.loadLatestResponse();
      setState(() {}); // refresh UI after loading
    });
  }

  Future<void> _loadJson(String lang) async {
    try {
      final path = lang == 'en'
          ? 'languages/maas_en.json'
          : 'languages/maas_si.json';
      final jsonStr = await rootBundle.loadString(path);
      final data = json.decode(jsonStr);

      setState(() {
        _questions = List<Map<String, dynamic>>.from(data['questions']);
        _options = Map<String, String>.from(data['options']);
      });
    } catch (e) {
      if (kDebugMode) print("MAAS JSON load error: $e");
    }
  }

  bool pageComplete(int pageIndex, MAASProvider provider) {
    int start = pageIndex * 5;
    int end = start + 5;
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

  // --- Updated Intro Screen ---
  Widget _buildIntroScreen(
    LanguageProvider langProvider,
    MAASProvider provider,
  ) {
    final hasPrevious = provider.latestMAASScore != null;
    final score = provider.latestMAASScore?.toStringAsFixed(2) ?? '';
    final classification = provider.latestMAASClassification ?? '';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              langProvider.currentLang == 'en'
                  ? "Welcome to MAAS Feedback"
                  : "MAAS ප්‍රතිචාර වෙත ඔබ සාදරයෙන් පිළිගනිමු",
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
                  ? "This feedback helps you understand your mindfulness levels. Answer honestly to get accurate scores."
                  : "මෙම ප්‍රතිචාරය ඔබේ මනෝසමීක්ෂණ මට්ටම් වටහා ගැනීමට උපකාරී වේ. නිවැරදි පිළිතුරු ලබාදීමට අවංකව පිළිතුරු දෙන්න.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: AppColors.text),
            ),
            const SizedBox(height: 32),

            // Start Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasPrevious
                      ? Colors.green
                      : AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  if (hasPrevious) {
                    // Confirmation dialog
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text(
                          langProvider.currentLang == 'en'
                              ? "Already Submitted"
                              : "පැමිණිලි කර ඇත",
                        ),
                        content: Text(
                          langProvider.currentLang == 'en'
                              ? "You have already submitted your MAAS responses. Do you want to change your answers?"
                              : "ඔබ දැනටමත් MAAS ප්‍රතිචාර පිරවා ඇත. පිළිතුරු වෙනස් කිරීමට අවශ්‍යද?",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              langProvider.currentLang == 'en' ? "No" : "නැහැ",
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              setState(() => _started = true);
                              _scrollToTop();
                            },
                            child: Text(
                              langProvider.currentLang == 'en' ? "Yes" : "ඔව්",
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    setState(() => _started = true);
                    _scrollToTop();
                  }
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

            // Previous score display
            if (hasPrevious) ...[
              const SizedBox(height: 12),
              Text(
                langProvider.currentLang == 'en'
                    ? "Previous Score: $score"
                    : "පෙර ලකුණු: $score",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                langProvider.currentLang == 'en'
                    ? "Classification: $classification"
                    : "වර්ගීකරණය: $classification",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _getClassificationColor(classification),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScoreRow(String title, String score, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(title, style: const TextStyle(fontSize: 16))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color, width: 1.5),
            ),
            child: Text(
              score,
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

  Color _getClassificationColor(String classification) {
    switch (classification) {
      case 'High Mindful Attention':
        return Colors.green;
      case 'Average Mindful Attention':
        return Colors.orange;
      case 'Low Mindful Attention':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MAASProvider>(context);
    final langProvider = Provider.of<LanguageProvider>(context);
    final totalPages = (_questions.length / 5).ceil();
    final isMobile = MediaQuery.of(context).size.width < 600;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            langProvider.currentLang == 'en'
                ? 'MAAS Feedback'
                : 'MAAS ප්‍රතිචාර',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: AppColors.primary,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: _questions.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : !_started
            ? _buildIntroScreen(langProvider, provider)
            : Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    // Progress bar
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        children: [
                          LinearProgressIndicator(
                            value: (_currentPage + 1) / totalPages,
                            backgroundColor: AppColors.accent.withOpacity(0.3),
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
                        itemCount: 5,
                        itemBuilder: (context, index) {
                          int qIndex = _currentPage * 5 + index;
                          if (qIndex >= _questions.length)
                            return const SizedBox();

                          final q = _questions[qIndex];
                          return Card(
                            color: AppColors.cardBackground,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 3,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                      groupValue: provider.responses[qIndex],
                                      title: Text(
                                        entry.value,
                                        style: TextStyle(
                                          fontSize: isMobile ? 13 : 15,
                                          color: AppColors.text,
                                        ),
                                      ),
                                      onChanged: (val) {
                                        if (val != null)
                                          provider.setAnswer(qIndex + 1, val);
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
                                horizontal: 4,
                              ),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.buttonPrevBack,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
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
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _isSubmitting
                                  ? null
                                  : () async {
                                      if (!pageComplete(
                                        _currentPage,
                                        provider,
                                      )) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
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
                                        setState(() => _isSubmitting = true);
                                        try {
                                          await provider.saveToFirebase(
                                            context,
                                          );
                                          final maasScore = provider
                                              .calculateMAASScore();
                                          final classification = provider
                                              .classifyScore(maasScore);
                                          final color = _getClassificationColor(
                                            classification,
                                          );

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
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
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
                                                            ? "MAAS Results"
                                                            : "MAAS ප්‍රතිඵල",
                                                        style: const TextStyle(
                                                          fontSize: 22,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color:
                                                              AppColors.primary,
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        height: 20,
                                                      ),
                                                      _buildScoreRow(
                                                        langProvider.currentLang ==
                                                                'en'
                                                            ? "Score"
                                                            : "ලකුණු",
                                                        maasScore
                                                            .toStringAsFixed(2),
                                                        color,
                                                      ),
                                                      _buildScoreRow(
                                                        langProvider.currentLang ==
                                                                'en'
                                                            ? "Classification"
                                                            : "වර්ගීකරණය",
                                                        classification,
                                                        color,
                                                      ),
                                                      const SizedBox(
                                                        height: 24,
                                                      ),
                                                      SizedBox(
                                                        width: double.infinity,
                                                        child: ElevatedButton(
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor:
                                                                AppColors
                                                                    .primary,
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  vertical: 14,
                                                                ),
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    12,
                                                                  ),
                                                            ),
                                                          ),
                                                          onPressed: () {
                                                            provider.reset();
                                                            setState(() {
                                                              _currentPage = 0;
                                                              _started = false;
                                                              _isSubmitting =
                                                                  false;
                                                            });
                                                            Navigator.pop(
                                                              context,
                                                            );
                                                            _scrollToTop();
                                                          },
                                                          child: Text(
                                                            langProvider.currentLang ==
                                                                    'en'
                                                                ? "OK"
                                                                : "හරි",
                                                            style: const TextStyle(
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
                                            print("Error saving MAAS: $e");
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                langProvider.currentLang == 'en'
                                                    ? "Error saving responses. Try again."
                                                    : "පිළිතුරු සුරැකිමේදී දෝෂයක්. නැවත උත්සාහ කරන්න.",
                                              ),
                                            ),
                                          );
                                        } finally {
                                          setState(() => _isSubmitting = false);
                                        }
                                      }
                                    },
                              child: _isSubmitting
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
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
