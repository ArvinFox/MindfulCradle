import 'package:flutter/material.dart';
import 'package:mamamind/screens/RAG_Chat/rag_chat_help.dart';
import 'package:mamamind/screens/home/questionnaires.dart';
import '../screens/home/video_player.dart';
import '../screens/home/home_page.dart';
import '../screens/main_screen.dart';
import '../screens/profile/gdpr_account_screen.dart';
import '../models/video_model.dart';

class HomeRoutes {
  static Map<String, WidgetBuilder> routes = {
    '/main-screen': (context) => const MainScreen(),
    '/home': (context) => const HomePage(),
    '/questionnaire': (context) => const QuestionnaireMainPage(),
    '/chat': (context) => const ChatBotPage(),
    '/gdpr-account': (context) => const GDPRAccountScreen(),
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
      ),
    );
  }
}
