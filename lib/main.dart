import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mamamind/providers/dass21_provider.dart';
import 'package:mamamind/providers/language_provider.dart';
import 'package:mamamind/providers/maas_provider.dart';
import 'package:mamamind/providers/pws18_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'providers/auth_provider.dart';
import 'providers/connectivity_provider.dart';
import 'providers/video_provider.dart';
import 'providers/achievement_provider.dart';
import 'providers/journal_provider.dart';
import 'providers/mood_provider.dart';
import 'services/localization_service.dart';
import 'services/notification_service.dart';
import 'services/crisis_detection_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    if (kDebugMode) debugPrint('Env load error: $e');
  }

  try {
    if (kDebugMode) debugPrint("Initializing Firebase...");
    await Firebase.initializeApp();
    if (kDebugMode) debugPrint("Firebase initialized successfully.");
  } catch (e) {
    if (kDebugMode) debugPrint("Firebase initialization error.");
  }

  // Initialize localization service
  try {
    if (kDebugMode) debugPrint("Loading translations...");
    await LocalizationService.instance.loadTranslations();
    if (kDebugMode) debugPrint("Translations loaded successfully.");
  } catch (e) {
    if (kDebugMode) debugPrint("Translations loading error: $e");
  }

  // Initialize notification service
  try {
    if (kDebugMode) debugPrint('Initializing notifications...');
    await NotificationService().initialize();
    if (kDebugMode) debugPrint('Notifications initialized successfully.');
  } catch (e) {
    if (kDebugMode) debugPrint('Notifications initialization error: $e');
  }

  // Load crisis detection keywords from JSON asset
  try {
    await CrisisDetectionService.loadKeywords();
    if (kDebugMode) debugPrint("Crisis keywords loaded successfully.");
  } catch (e) {
    if (kDebugMode) debugPrint("Crisis keywords loading error: $e");
  }

  // Read onboarding flag before building the widget tree so routing is
  // always deterministic, regardless of device speed.
  final prefs = await SharedPreferences.getInstance();
  final hasSeenOnboarding = prefs.getBool('onboarding_complete') ?? false;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
        ChangeNotifierProvider(create: (_) => VideoProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => DASS21Provider()),
        ChangeNotifierProvider(create: (_) => MAASProvider()),
        ChangeNotifierProvider(create: (_) => PWS18Provider()),
        ChangeNotifierProvider(create: (_) => AchievementProvider()),
        ChangeNotifierProvider(create: (_) => JournalProvider()),
        ChangeNotifierProvider(create: (_) => MoodProvider()),
      ],
      child: MyApp(hasSeenOnboarding: hasSeenOnboarding),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool hasSeenOnboarding;

  const MyApp({super.key, required this.hasSeenOnboarding});

  @override
  Widget build(BuildContext context) {
    return MindfulCradleApp(hasSeenOnboarding: hasSeenOnboarding);
  }
}
