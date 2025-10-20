import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mamamind/utils/helpers.dart';
import 'package:provider/provider.dart';
import 'package:mamamind/screens/home/questionnaires.dart';
import '../../constants/colors.dart';
import '../../providers/language_provider.dart';
import 'home/home_page.dart';
import 'achievements/achievements_page.dart';
import 'profile/profile_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  DateTime? lastBackPressTime;

  final List<Widget> _pages = const [
    HomePage(),
    QuestionnaireMainPage(),
    AchievementsPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    // Lock the screen to portrait
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  //  Bottom navigation bar
  Widget _buildBottomNavigationBar(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final isSinhala = langProvider.currentLang == 'si';

    final List<String> labels = isSinhala
        ? ["මුල් පිටුව", "ප්‍රතිචාර", "ජයග්‍රහණ", "ප්‍රොෆයිල්"]
        : ["Home", "Feedback", "Achievements", "Profile"];

    return BottomNavigationBar(
      currentIndex: _currentIndex,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.text.withOpacity(0.6),
      backgroundColor: AppColors.background,
      elevation: 10,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: selectedLabelStyle,
      unselectedLabelStyle: unselectedLabelStyle,
      
      onTap: (index) {
        HapticFeedback.lightImpact();
        setState(() {
          _currentIndex = index;
        });
      },
      items: [
        BottomNavigationBarItem(
            icon: const Icon(Icons.home_rounded), label: labels[0]),
        BottomNavigationBarItem(
          icon: const Icon(Icons.assignment),
          label: labels[1],
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.star_rounded),
          label: labels[2],
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.person_rounded),
          label: labels[3],
        ),
      ],
    );
  }

  // --- Main Build Method ---

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final isSinhala = langProvider.currentLang == 'si';

    final String exitMessage = isSinhala
        ? "යෙදුමෙන් පිටවීමට නැවත පිටුපස ඔබන්න"
        : "Press back again to exit app";

    return WillPopScope(
      onWillPop: () async {
        if (_currentIndex != 0) {
          HapticFeedback.lightImpact();
          setState(() {
            _currentIndex = 0;
          });
          return false;
        }

        DateTime now = DateTime.now();
        if (lastBackPressTime == null ||
            now.difference(lastBackPressTime!) > const Duration(seconds: 2)) {
          
          HapticFeedback.mediumImpact();
          lastBackPressTime = now;
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                exitMessage,
                style: TextStyle(color: AppColors.buttonText),
              ),
              backgroundColor: AppColors.primary,
              duration: const Duration(seconds: 2),
            ),
          );
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _pages[_currentIndex],
        ),
        bottomNavigationBar: _buildBottomNavigationBar(context),
      ),
    );
  }
}