import 'package:flutter/material.dart';
import 'package:mamamind/screens/splashScreen/splash_screen.dart';
import 'package:mamamind/screens/auth/login_page.dart';
import 'package:mamamind/screens/auth/signup_page.dart';
import 'package:mamamind/screens/auth/forgot_password_page.dart';
import '../screens/auth/user_registration_page.dart';
import '../models/user_model.dart';

class AuthRoutes {
  static Map<String, WidgetBuilder> routes = {
    '/splash': (context) => const SplashPage(),
    '/login': (context) => const LoginPage(),
    '/signup': (context) => const SignupPage(),
    '/forgot-password': (context) => const ForgotPasswordPage(),
  };

  static void goToUserRegistrationForm(BuildContext context, UserModel user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserRegistrationPage(user: user),
      ),
    );
  }
}
