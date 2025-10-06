import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/colors.dart';
import '../../constants/app_config.dart';
import '../../utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../utils/helpers.dart';
import 'user_registration_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';
  bool rememberMe = false;
  String? errorMessage;
  bool isPasswordVisible = false;

  Future<void> _handleLogin(
    BuildContext context,
    AuthProvider authProvider,
  ) async {
    // 1. Initial State & Validation
    setState(() => errorMessage = null);
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.lightImpact();
      return;
    }
    _formKey.currentState!.save();

    final result = await authProvider.login(
      email,
      password,
      rememberMe: rememberMe,
    );

    if (!mounted) return;

    if (result == null) {
      HapticFeedback.mediumImpact();

      try {
        final uid = FirebaseAuth.instance.currentUser!.uid;
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();

        final isComplete =
            userDoc.data()?['isUserRegistrationComplete'] ?? false;

        if (!isComplete) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => UserRegistrationPage(user: authProvider.user!),
            ),
          );
        } else {
          Navigator.pushReplacementNamed(context, '/main-screen');
        }
      } catch (e) {
        setState(
          () => errorMessage = "Error loading user data. Please try again.",
        );
      }
    } else {
      // UX: Error Haptic Feedback
      HapticFeedback.vibrate();
      setState(() => errorMessage = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final langProvider = Provider.of<LanguageProvider>(context);

    // Translations
    final loginText = langProvider.currentLang == 'en' ? "Login" : "ඇතුළු වන්න";
    final emailText = langProvider.currentLang == 'en' ? "Email" : "ඊමේල්";
    final passwordText = langProvider.currentLang == 'en'
        ? "Password"
        : "මුරපදය";
    final rememberMeText = langProvider.currentLang == 'en'
        ? "Remember Me"
        : "මතක් කරන්න";
    final forgotPasswordText = langProvider.currentLang == 'en'
        ? "Forgot Password?"
        : "මුරපදය අමතකද?";
    final dontHaveAccountText = langProvider.currentLang == 'en'
        ? "Don't have an account? "
        : "ගිණුමක් නැද්ද? ";
    final signUpText = langProvider.currentLang == 'en'
        ? "Sign Up"
        : "ලියාපදිංචි වන්න";

    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.isInitializing) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          body: Stack(
            children: [
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/login/app_background.png"),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              Container(
                width: double.infinity,
                height: double.infinity,
                color: AppColors.background.withOpacity(0.10),
              ),

              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 40,
                  ),
                  child: Container(
                    width: isMobile ? size.width * 0.9 : 400,
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 3,
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.05),
                          spreadRadius: -2,
                          blurRadius: 10,
                          offset: const Offset(-5, -5),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.inputBackground,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.1),
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: langProvider.currentLang == 'en'
                                      ? "English"
                                      : "සිංහල",
                                  style: GoogleFonts.roboto(
                                    fontSize: 14,
                                    color: AppColors.text,
                                  ),
                                  iconEnabledColor: AppColors.text,
                                  items: [
                                    DropdownMenuItem(
                                      value: "English",
                                      child: Text(
                                        "English",
                                        style: TextStyle(color: AppColors.text),
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: "සිංහල",
                                      child: Text(
                                        "සිංහල",
                                        style: TextStyle(color: AppColors.text),
                                      ),
                                    ),
                                  ],
                                  onChanged: (val) {
                                    if (val == null) return;
                                    langProvider.setLanguage(
                                      val == "English" ? "en" : "si",
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),

                          Text(
                            AppConfig.appName,
                            style: GoogleFonts.poppins(
                              fontSize: isMobile ? 36 : 42,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Error Message
                          if (errorMessage != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.red.shade300),
                              ),
                              child: Text(
                                errorMessage!,
                                style: GoogleFonts.roboto(
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),

                          // Email Field
                          TextFormField(
                            keyboardType: TextInputType.emailAddress,
                            decoration: customInputDecoration(emailText)
                                .copyWith(
                                  prefixIcon: const Icon(
                                    Icons.email_outlined,
                                    color: AppColors.primary,
                                  ),
                                ),
                            validator: Validators.validateEmail,
                            onSaved: (val) => email = val ?? '',
                          ),
                          const SizedBox(height: 20),

                          // Password Field
                          TextFormField(
                            obscureText: !isPasswordVisible,
                            decoration: customInputDecoration(passwordText)
                                .copyWith(
                                  prefixIcon: const Icon(
                                    Icons.lock_outline,
                                    color: AppColors.primary,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      isPasswordVisible
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: AppColors.text.withOpacity(0.6),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        isPasswordVisible = !isPasswordVisible;
                                      });
                                    },
                                  ),
                                ),
                            validator: Validators.validatePassword,
                            onSaved: (val) => password = val ?? '',
                          ),
                          const SizedBox(height: 10),

                          // Remember Me & Forgot Password
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () =>
                                    setState(() => rememberMe = !rememberMe),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: rememberMe,
                                      onChanged: (val) => setState(
                                        () => rememberMe = val ?? false,
                                      ),
                                      activeColor: AppColors.primary,
                                    ),
                                    Text(
                                      rememberMeText,
                                      style: GoogleFonts.roboto(),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  '/forgot-password',
                                ),
                                child: Text(
                                  forgotPasswordText,
                                  style: GoogleFonts.roboto(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),

                          // Login Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.buttonText,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: 5,
                              ),
                              onPressed: authProvider.isLoading
                                  ? null
                                  : () => _handleLogin(context, authProvider),
                              child: authProvider.isLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 3,
                                      ),
                                    )
                                  : Text(
                                      loginText,
                                      style: GoogleFonts.poppins(
                                        fontSize: isMobile ? 18 : 20,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.buttonText,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Sign Up Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                dontHaveAccountText,
                                style: GoogleFonts.roboto(
                                  color: AppColors.text,
                                ),
                              ),
                              GestureDetector(
                                onTap: () =>
                                    Navigator.pushNamed(context, '/signup'),
                                child: Text(
                                  signUpText,
                                  style: GoogleFonts.roboto(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
