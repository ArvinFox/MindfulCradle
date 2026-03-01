import 'package:flutter/material.dart';
import 'package:mamamind/utils/helpers.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:marquee/marquee.dart';
import '../../constants/colors.dart';
import '/providers/language_provider.dart';
import '../questionnaires/dass21_questionnaire/dass21_questionnaire_start.dart';
import '../questionnaires/maas_questionnaire/maas_questionnaire_start.dart';
import '../questionnaires/pws18_questionnaire/pws18_questionnaire_start.dart';

class QuestionnaireMainPage extends StatefulWidget {
  const QuestionnaireMainPage({super.key});

  @override
  State<QuestionnaireMainPage> createState() => _QuestionnaireMainPageState();
}

class _QuestionnaireMainPageState extends State<QuestionnaireMainPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    final tabTitles = lang.currentLang == 'en'
        ? ["Feelings Checker", "Attention Checker", "Happiness Score"]
        : ["හැඟීම් පරික්ෂාව", "සතිමත් බව පරීක්ෂාව", "මානසික සතුට පරීක්ෂාව"];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          lang.currentLang == 'en' ? "Feedbacks" : "ප්‍රතිචාර",
          style: appBarTextStyle,
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: List.generate(tabTitles.length, (index) {
            final isActive = _tabController.index == index;
            return Tab(
              child: SizedBox(
                height: 20,
                child: isActive
                    ? Marquee(
                        text: tabTitles[index],
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                        scrollAxis: Axis.horizontal,
                        blankSpace: 20,
                        velocity: 30,
                        startAfter: const Duration(seconds: 1),
                        pauseAfterRound: const Duration(seconds: 1),
                      )
                    : Text(
                        tabTitles[index],
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
            );
          }),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          DASS21QuestionnaireStartPage(),
          MAASQuestionnaireStartPage(),
          PWS18QuestionnaireStartPage(),
        ],
      ),
    );
  }
}
