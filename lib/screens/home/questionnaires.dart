import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../constants/colors.dart';
import '../../providers/language_provider.dart';
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
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final isSinhala = lang.currentLang == 'si';

    final tabTitles = isSinhala
        ? ['හැඟීම්', 'සතිමත් බව', 'සතුට']
        : ['Feelings', 'Attention', 'Happiness'];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          isSinhala ? 'ප්‍රතිචාර' : 'Feedback',
          style: GoogleFonts.poppins(
            color: AppColors.text,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFF8F5F2), Color(0xFFF4F0EC)],
                ),
              ),
            ),
          ),
          Positioned(
            right: -50,
            top: -50,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: AppColors.heroGradientMid.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.heroGradientStart,
                        AppColors.heroGradientMid,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.18),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSinhala
                            ? 'ඔබේ මනස අද කොහොමද?'
                            : 'How is your mind today?',
                        style: GoogleFonts.poppins(
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isSinhala
                            ? 'තත්ත්වය නිරීක්ෂණය කර ඉදිරි සැලැස්ම සකසන්න.'
                            : 'Track your state and shape your next mindful step.',
                        style: GoogleFonts.roboto(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.92),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    dividerColor: Colors.transparent,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textMuted,
                    labelStyle: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    unselectedLabelStyle: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    tabs: tabTitles.map((title) => Tab(text: title)).toList(),
                  ),
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    DASS21QuestionnaireStartPage(),
                    MAASQuestionnaireStartPage(),
                    PWS18QuestionnaireStartPage(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
