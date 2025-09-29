import 'package:flutter/material.dart';
import '../screens/home/video_player.dart';
import '../screens/home/home_page.dart';
import '../screens/main_screen.dart';
import '../models/video_model.dart';

class HomeRoutes {
  static Map<String, WidgetBuilder> routes = {
    '/main-screen': (context) => const MainScreen(),
    '/home': (context) => const HomePage(),
  };

  /// Navigate to video player page with user-specific tracking
  static void goToVideoPlayer(BuildContext context, VideoModel video, String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => YouTubeVideoPlayerPage(
          video: video,
          userId: userId,
        ),
      ),
    );
  }
}
