import 'package:flutter/material.dart';
import 'package:mamamind/screens/RAG_Chat/rag_chat_help.dart';
import 'package:mamamind/screens/home/questionnaires.dart';
import '../screens/home/video_player.dart';
import '../screens/home/home_page.dart';
import '../screens/main_screen.dart';
import '../screens/profile/gdpr_account_screen.dart';
import '../screens/profile/notification_settings_screen.dart';
import '../models/video_model.dart';

class HomeRoutes {
  static Map<String, WidgetBuilder> routes = {
    '/main-screen': (context) => const MainScreen(),
    '/home': (context) => const HomePage(),
    '/questionnaire': (context) => const QuestionnaireMainPage(),
    '/chat': (context) => const ChatBotPage(),
    '/gdpr-account': (context) => const GDPRAccountScreen(),
    '/notification-settings': (context) => const NotificationSettingsScreen(),
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
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            YouTubeVideoPlayerPage(
          video: video,
          userId: userId,
          youtubeId: youtubeId,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Use a simple fade transition to avoid complex animations that might interfere with video player
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        // Ensure the route maintains state properly
        maintainState: false,
        fullscreenDialog: false,
      ),
    );
  }
}
