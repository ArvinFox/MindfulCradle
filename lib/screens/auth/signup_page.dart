import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/colors.dart';
import '../../utils/validators.dart';
import '../../services/auth_service.dart';
import '../../utils/helpers.dart';
import '../../providers/language_provider.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;

  final AuthService _authService = AuthService();
  bool loading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  // Helper function - signup logic
  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.lightImpact();
      return;
    }

    setState(() => loading = true);

    try {
      final result = await _authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        fullName: _fullNameController.text.trim(),
      );

      if (!mounted) return;

      if (result == null) {
        // Success feedback
        HapticFeedback.mediumImpact();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Provider.of<LanguageProvider>(
                        context,
                        listen: false,
                      ).currentLang ==
                      'en'
                  ? "Account created successfully! Please login."
                  : "ගිණුම සාර්ථකව සෑදන ලදි! කරුණාකර ඇතුළු වන්න.",
            ),
          ),
        );

        _fullNameController.clear();
        _emailController.clear();
        _passwordController.clear();
        _confirmController.clear();

        Navigator.pushReplacementNamed(context, '/login');
      } else {
        // Error feedback
        HapticFeedback.vibrate();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result)));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("An unexpected error occurred.")));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    final langProvider = Provider.of<LanguageProvider>(context);

    // Translations
    final signUpText = langProvider.currentLang == 'en'
        ? "Sign Up"
        : "ලියාපදිංචි වන්න";
    final fullNameText = langProvider.currentLang == 'en'
        ? "Full Name"
        : "සම්පූර්ණ නම";
    final emailText = langProvider.currentLang == 'en' ? "Email" : "ඊමේල්";
    final passwordText = langProvider.currentLang == 'en'
        ? "Password"
        : "මුරපදය";
    final confirmPasswordText = langProvider.currentLang == 'en'
        ? "Confirm Password"
        : "මුරපදය තහවුරු කරන්න";
    final alreadyHaveAccountText = langProvider.currentLang == 'en'
        ? "Already have an account? "
        : "දැනටම ගිණුමක් තිබේද? ";
    final loginText = langProvider.currentLang == 'en' ? "Login" : "ඇතුළු වන්න";

    return Scaffold(
      body: Stack(
        children: [
          // 1. Background image
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
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
                      Text(
                        signUpText,
                        style: GoogleFonts.poppins(
                          fontSize: isMobile ? 36 : 42,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Full Name
                      TextFormField(
                        controller: _fullNameController,
                        keyboardType: TextInputType.name,
                        decoration: customInputDecoration(fullNameText)
                            .copyWith(
                              prefixIcon: const Icon(
                                Icons.person_outline,
                                color: AppColors.primary,
                              ),
                            ),
                        validator: Validators.validateName,
                      ),
                      const SizedBox(height: 20),

                      // Email
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: customInputDecoration(emailText).copyWith(
                          prefixIcon: const Icon(
                            Icons.email_outlined,
                            color: AppColors.primary,
                          ),
                        ),
                        validator: Validators.validateEmail,
                      ),
                      const SizedBox(height: 20),

                      // Password
                      TextFormField(
                        controller: _passwordController,
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
                      ),
                      const SizedBox(height: 20),

                      // Confirm Password
                      TextFormField(
                        controller: _confirmController,
                        obscureText: !isConfirmPasswordVisible,
                        decoration: customInputDecoration(confirmPasswordText)
                            .copyWith(
                              prefixIcon: const Icon(
                                Icons.lock_reset,
                                color: AppColors.primary,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  isConfirmPasswordVisible
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: AppColors.text.withOpacity(0.6),
                                ),
                                onPressed: () {
                                  setState(() {
                                    isConfirmPasswordVisible =
                                        !isConfirmPasswordVisible;
                                  });
                                },
                              ),
                            ),
                        validator: (val) => Validators.validateConfirmPassword(
                          _passwordController.text,
                          val,
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Signup Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.buttonText,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 5,
                          ),
                          onPressed: loading ? null : _handleSignup,
                          child: loading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                )
                              : Text(
                                  signUpText,
                                  style: GoogleFonts.poppins(
                                    fontSize: isMobile ? 18 : 20,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.buttonText,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      // Login Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            alreadyHaveAccountText,
                            style: GoogleFonts.roboto(
                              color: AppColors.text,
                            ), // Using Roboto font
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context, '/login');
                            },
                            child: Text(
                              loginText,
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
  }
}
