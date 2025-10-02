import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../questionnaires/daas21_questionnaire.dart';
import '../questionnaires/maas_questionnaire.dart';
import '../questionnaires/pwb18_questionnaire.dart';

class QuestionnaireMainPage extends StatelessWidget {
  const QuestionnaireMainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          title: const Text(
            "Questionnaire Feedback",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: "DAAS-21"),
              Tab(text: "MAAS"),
              Tab(text: "PWS-18"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            DAAS21Page(), // DAAS flow 
          ],
        ),
      ),
    );
  }
}
