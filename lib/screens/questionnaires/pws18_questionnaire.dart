import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/constants/colors.dart';
import '/providers/pws18_provider.dart';
import '/providers/language_provider.dart';
import 'pws18_questionnaire/autonomy.dart';
import 'pws18_questionnaire/environmental_mastery.dart';
import 'pws18_questionnaire/personal_growth.dart';
import 'pws18_questionnaire/positive_relations_with_others.dart';
import 'pws18_questionnaire/purpose_in_life.dart';
import 'pws18_questionnaire/self_acceptance.dart';

class PWS18QuestionnairePage extends StatefulWidget {
  const PWS18QuestionnairePage({super.key});

  @override
  State<PWS18QuestionnairePage> createState() => _PWS18QuestionnairePageState();
}

class _PWS18QuestionnairePageState extends State<PWS18QuestionnairePage> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final provider = Provider.of<PWS18Provider>(context, listen: false);
      provider.loadLatest(context);
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final provider = Provider.of<PWS18Provider>(context);
    final isSinhala = langProvider.currentLang == 'si';

    // 🔹 Show loading screen if data is fetching
    if (provider.isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            isSinhala ? 'PWS-18 ප්‍රශ්නාවලිය' : 'PWS-18 Questionnaire',
            style: const TextStyle(color: Colors.white),
          ),
          centerTitle: true,
          backgroundColor: AppColors.primary,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final categories = [
      {
        'key': 'Autonomy',
        'title': isSinhala ? 'ස්වයංක්‍රමතාව' : 'Autonomy',
        'page': const AutonomyPage(),
      },
      {
        'key': 'Environmental Mastery',
        'title': isSinhala ? 'පරිසර පාලනය' : 'Environmental Mastery',
        'page': const EnvironmentalMasteryPage(),
      },
      {
        'key': 'Personal Growth',
        'title': isSinhala ? 'පුද්ගලික වර්ධනය' : 'Personal Growth',
        'page': const PersonalGrowthPage(),
      },
      {
        'key': 'Positive Relations with Others',
        'title': isSinhala ? 'අන් අය සමඟ සම්බන්ධතා' : 'Positive Relations',
        'page': const PositiveRelationsPage(),
      },
      {
        'key': 'Purpose in Life',
        'title': isSinhala ? 'ජීවිතයට අරමුණ' : 'Purpose in Life',
        'page': const PurposeInLifePage(),
      },
      {
        'key': 'Self-Acceptance',
        'title': isSinhala ? 'ස්වයං-ග්‍රහණය' : 'Self-Acceptance',
        'page': const SelfAcceptancePage(),
      },
    ];

    Map<String, bool> answeredMap = {};
    for (var category in provider.subscales.keys) {
      answeredMap[category] = provider.subscales[category]!.every(
        (qId) => provider.responses[qId - 1] != null,
      );
    }

    final allCompleted = answeredMap.values.every((v) => v);
    final subscaleScores = allCompleted ? provider.calculateScores() : {};

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          isSinhala ? 'PWS-18 ප්‍රශ්නාවලිය' : 'PWS-18 Questionnaire',
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              isSinhala
                  ? 'ප්‍රශ්නාවලියේ කොටසක් තෝරන්න:'
                  : 'Select a category to answer the questions:',
              style: TextStyle(fontSize: 18, color: AppColors.text),
            ),
            const SizedBox(height: 24),

            // Category Grid
            Expanded(
              child: GridView.builder(
                itemCount: categories.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 3 / 2,
                ),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final key = category['key'] as String;
                  final answered = answeredMap[key] == true;

                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: answered
                          ? AppColors.completed
                          : AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(16),
                    ),
                    onPressed: () async {
                      if (answered) {
                        final edit = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(
                              isSinhala
                                  ? 'පිළිතුරු සංස්කරණය කරන්න'
                                  : 'Edit Response?',
                            ),
                            content: Text(
                              isSinhala
                                  ? 'මෙම කොටසට ඔබ දී ඇති පිළිතුරු වෙනස් කිරීමට අවශ්‍යද?'
                                  : 'Do you want to edit your answers for this category?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(isSinhala ? 'නැහැ' : 'No'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text(isSinhala ? 'ඔව්' : 'Yes'),
                              ),
                            ],
                          ),
                        );
                        if (edit != true) return;
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => category['page'] as Widget,
                        ),
                      );
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          category['title'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.buttonText,
                          ),
                        ),
                        if (answered)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              isSinhala ? 'පිළිතුරු දී ඇත' : 'Answered',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Final results as tiles
            if (allCompleted) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  isSinhala ? 'අවසන් ප්‍රතිඵල' : 'Final Results',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 110, // compact height
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: subscaleScores.entries.map((e) {
                    return Container(
                      width: 120,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            e.key,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                            maxLines: 2, 
                            overflow: TextOverflow.visible,
                          ),
                          Text(
                            e.value.toStringAsFixed(2),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
