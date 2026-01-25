import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mamamind/constants/app_config.dart';
import 'package:mamamind/constants/colors.dart';
import 'package:mamamind/routes/app_routes.dart';
import 'package:mamamind/providers/auth_provider.dart';
import 'package:mamamind/screens/auth/login_page.dart';
import 'package:mamamind/screens/auth/user_registration_page.dart';
import 'package:mamamind/screens/main_screen.dart';
import 'package:mamamind/screens/splashScreen/splash_screen.dart';
import 'package:mamamind/utils/globals.dart';

class MamaMindApp extends StatefulWidget {
  const MamaMindApp({super.key});

  @override
  State<MamaMindApp> createState() => _MamaMindAppState();
}

class _MamaMindAppState extends State<MamaMindApp> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();

    // Always show splash for at least 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _showSplash = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        Widget home;

        // Show splash screen while initializing or during delay
        if (authProvider.isInitializing || _showSplash) {
          home = const SplashPage();
        } else if (authProvider.isLoggedIn) {
          final user = authProvider.user;

          // If user registration incomplete → go to registration page
          if (user != null &&
              (user.toMap()['isUserRegistrationComplete'] ?? false) == false) {
            home = UserRegistrationPage(user: user);
          } else {
            home = const MainScreen();
          }
        } else {
          // Not logged in
          home = const LoginPage();
        }

        return MaterialApp(
          title: AppConfig.appName,
          debugShowCheckedModeBanner: false,
          scaffoldMessengerKey:
              rootScaffoldMessengerKey, // For Global Snackbars
          navigatorKey: navigatorKey, // For Global Dialogs

          theme: ThemeData(
            primaryColor: AppColors.primary,
            scaffoldBackgroundColor: AppColors.background,
            textTheme: Theme.of(context).textTheme.apply(
              bodyColor: AppColors.text,
              displayColor: AppColors.text,
            ),
          ),
          home: home,
          routes: AppRoutes.routes,
        );
      },
    );
  }
}
