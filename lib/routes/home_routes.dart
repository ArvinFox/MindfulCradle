import 'package:flutter/material.dart';
import 'package:mamamind/screens/home/home_page.dart';
import 'package:mamamind/screens/home/video_player.dart';
import 'package:mamamind/screens/main_screen.dart';

class HomeRoutes {
  static Map<String, WidgetBuilder> routes = {
    '/main-screen' : (context) => const MainScreen(),
    '/home': (context) => const HomePage(),
    // '/video-player': (context) => const VideoPlayerPage(videoUrl: "",),
  };
}
