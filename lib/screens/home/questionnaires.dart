import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/colors.dart';
import '/providers/language_provider.dart';
import '/screens/questionnaires/daas21_questionnaire.dart';
import '/screens/questionnaires/maas_questionnaire.dart';
import '/screens/questionnaires/pws18_questionnaire.dart';

class QuestionnaireMainPage extends StatelessWidget {
  const QuestionnaireMainPage({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    // Dynamic Tab Labels
    final List<String> tabTitles = lang.currentLang == 'en'
        ? ["DAAS-21", "MAAS", "PWS-18"]
        : ["DAAS-21", "MAAS", "PWS-18"];

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          elevation: 4, 
          title: Text(
            lang.currentLang == 'en'
                ? "Questionnaire Feedback"
                : "ප්‍රශ්න පිළිබඳ ප්‍රතිචාර",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600, 
            ),
          ),
          centerTitle: true,
          bottom: TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3.0, 
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withOpacity(0.75), 
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w600, 
              fontSize: 15,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
            tabs: tabTitles.map((title) => Tab(text: title)).toList(),
          ),
        ),
        body: const TabBarView(
          children: [
            DAAS21Page(),
            MAASPage(),
            PWS18QuestionnairePage(),
          ],
        ),
      ),
    );
  }
}