import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '/constants/colors.dart';
import '/providers/pws18_provider.dart';
import '/providers/language_provider.dart';

class PositiveRelationsPage extends StatefulWidget {
  const PositiveRelationsPage({super.key});

  @override
  State<PositiveRelationsPage> createState() => _PositiveRelationsPageState();
}

class _PositiveRelationsPageState extends State<PositiveRelationsPage> {
  bool _started = false;
  bool _isSubmitting = false;
  List<Map<String, dynamic>> _questions = [];
  Map<String, String> _options = {};
  String _currentLang = '';

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

    final provider = Provider.of<PWS18Provider>(context, listen: false);
    provider.loadLatest(context);
  }

  Future<void> _loadJson(String lang) async {
    try {
      final path = lang == 'en'
          ? 'languages/pws18_en.json'
          : 'languages/pws18_si.json';
      final jsonStr = await rootBundle.loadString(path);
      final data = json.decode(jsonStr);

      setState(() {
        final provider = Provider.of<PWS18Provider>(context, listen: false);
        final ids = provider.subscales['Positive Relations with Others'] ?? [];
        _questions = List<Map<String, dynamic>>.from(
          data['questions'].where((q) => ids.contains(q['id'])),
        );
        _options = Map<String, String>.from(data['options']);
      });
    } catch (e) {
      if (kDebugMode) print("Positive Relations JSON load error: $e");
    }
  }

  bool _allAnswered(PWS18Provider provider) {
    final ids = provider.subscales['Positive Relations with Others'] ?? [];
    for (var id in ids) {
      if (provider.responses[id - 1] == null) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PWS18Provider>(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _currentLang == 'en' ? 'Positive Relations' : 'සහකාර සම්බන්ධතා',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        leading: CupertinoNavigationBarBackButton(
          color: Colors.white,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _questions.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : !_started
          ? _buildStartScreen()
          : _buildQuestionList(provider, isMobile),
    );
  }

  Widget _buildQuestionList(PWS18Provider provider, bool isMobile) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: _questions.length,
              itemBuilder: (context, index) {
                final q = _questions[index];
                final qId = q['id'];

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
                          '${index + 1}. ${q['question']}',
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
                            groupValue: provider.responses[qId - 1],
                            title: Text(
                              entry.value,
                              style: TextStyle(
                                fontSize: isMobile ? 13 : 15,
                                color: AppColors.text,
                              ),
                            ),
                            onChanged: (val) {
                              if (val != null) provider.setAnswer(qId, val);
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
              onPressed: !_allAnswered(provider) || _isSubmitting
                  ? null
                  : () async {
                      setState(() => _isSubmitting = true);
                      try {
                        await provider.saveCategoryAnswers(
                          'Positive Relations with Others',
                          context: context,
                        );

                        if (provider.allCategoriesAnswered()) {
                          final scores = provider.calculateScores();
                          await showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => Center(
                              child: SingleChildScrollView(
                                child: AlertDialog(
                                  backgroundColor: AppColors.background,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  contentPadding: const EdgeInsets.all(24),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _currentLang == 'en'
                                            ? "Final PWB-18 Scores"
                                            : "අවසන් PWB-18 ලකුණු",
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      ...scores.entries.map(
                                        (e) => Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 6,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  e.key,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary
                                                      .withOpacity(0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: AppColors.primary,
                                                    width: 1.5,
                                                  ),
                                                ),
                                                child: Text(
                                                  e.value.toStringAsFixed(2),
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.primary,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 14,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          onPressed: () {
                                            setState(() => _started = false);
                                            Navigator.of(context).pop();
                                            Navigator.of(context).pop();
                                          },
                                          child: Text(
                                            _currentLang == 'en' ? "OK" : "හරි",
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
                              ),
                            ),
                          );
                        } else {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                _currentLang == 'en'
                                    ? "Category completed! Answer other categories to get the final score."
                                    : "කොටස සම්පූර්ණයි! අවසන් ලකුණු ලබාගැනීමට අනෙකුත් කොටස් පිළිතුරු දෙන්න.",
                              ),
                            ),
                          );
                          setState(() => _started = false);
                        }
                      } catch (e) {
                        if (kDebugMode)
                          print("Error saving Positive Relations: $e");
                      } finally {
                        setState(() => _isSubmitting = false);
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
                      _currentLang == 'en' ? "Next" : "ඊළඟ",
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.buttonText,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildStartScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _currentLang == 'en'
                  ? "Positive Relations Questions"
                  : "සහකාර සම්බන්ධතා ප්‍රශ්න",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _currentLang == 'en'
                  ? "Answer honestly. Your responses are confidential."
                  : "නිවැරදිව පිළිතුරු ලබාදෙන්න. ඔබේ පිළිතුරු රහසිගත වේ.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: AppColors.text),
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
                onPressed: () => setState(() => _started = true),
                child: Text(
                  _currentLang == 'en' ? "Start" : "ආරම්භ කරන්න",
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
}
