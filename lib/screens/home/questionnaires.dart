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

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          title: Text(
            lang.currentLang == 'en'
                ? "Questionnaire Feedback"
                : "ප්‍රශ්න පිළිබඳ ප්‍රතිචාර",
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          bottom: TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(text: "DAAS-21"),
              Tab(text: "MAAS"),
              Tab(text: "PWS-18"),
            ],
          ),
        ),
        body: TabBarView(
          children: const [
            DAAS21Page(),
            MAASPage(),
            PWS18QuestionnairePage(),
          ],
        ),
      ),
    );
  }
}
