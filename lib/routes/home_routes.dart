import 'package:flutter/material.dart';
import 'package:mamamind/screens/home/home_page.dart';
import 'package:mamamind/screens/home/video_player.dart';

class HomeRoutes {
  static Map<String, WidgetBuilder> routes = {
    '/home': (context) => const HomePage(),
    // '/video-player': (context) => const VideoPlayerPage(videoUrl: "",),
  };
}
