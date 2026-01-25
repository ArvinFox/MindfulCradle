import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mamamind/providers/dass21_provider.dart';
import 'package:mamamind/providers/language_provider.dart';
import 'package:mamamind/providers/maas_provider.dart';
import 'package:mamamind/providers/pws18_provider.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/auth_provider.dart';
import 'providers/video_provider.dart';
import 'providers/achievement_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    print("Initializing Firebase...");
    await Firebase.initializeApp();
    print("Firebase initialized successfully.");
  } catch (e) {
    print("Firebase initialization error: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => VideoProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => DASS21Provider()),
        ChangeNotifierProvider(create: (_) => MAASProvider()),
        ChangeNotifierProvider(create: (_) => PWS18Provider()),
        ChangeNotifierProvider(create: (_) => AchievementProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MamaMindApp();
  }
}
