import 'package:flutter/material.dart';
import 'package:mamamind/screens/RAG_Chat/rag_chat_help.dart';
import 'package:mamamind/screens/home/questionnaires.dart';
import 'package:mamamind/screens/tutorial/app_tutorial_screen.dart';
import '../screens/home/video_player.dart';
import '../screens/home/home_page.dart';
import '../screens/main_screen.dart';
import '../screens/profile/gdpr_account_screen.dart';
import '../screens/profile/notification_settings_screen.dart';
import '../screens/profile/privacy_policy_screen.dart';
import '../models/video_model.dart';

class HomeRoutes {
  static Map<String, WidgetBuilder> routes = {
    '/main-screen': (context) => const MainScreen(),
    '/home': (context) => const HomePage(),
    '/tutorial': (context) => const AppTutorialScreen(),
    '/questionnaire': (context) => const QuestionnaireMainPage(),
    '/chat': (context) => const ChatBotPage(),
    '/gdpr-account': (context) => const GDPRAccountScreen(),
    '/notification-settings': (context) => const NotificationSettingsScreen(),
    '/privacy-policy': (context) => const PrivacyPolicyScreen(),
  };

  /// Navigate to video player page with user-specific tracking & language
  static void goToVideoPlayer(
    BuildContext context,
    VideoModel video,
    String userId,
    String youtubeId,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => YouTubeVideoPlayerPage(
          video: video,
          userId: userId,
          youtubeId: youtubeId,
        ),
        maintainState: false,
      ),
    );
  }
}
