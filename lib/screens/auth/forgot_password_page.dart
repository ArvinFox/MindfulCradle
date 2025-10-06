import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/colors.dart';
import '../../utils/validators.dart';
import '../../utils/helpers.dart';
import '../../services/auth_service.dart';
import '../../providers/language_provider.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final AuthService _authService = AuthService();
  bool loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // Logic to handle password reset request
  Future<void> _handlePasswordReset() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.lightImpact();
      return;
    }

    setState(() => loading = true);

    // Translations for feedback
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final passwordSentText = langProvider.currentLang == 'en'
        ? "Password reset link sent! Check your email."
        : "මුරපදය යළි පිහිටුම් සබැඳිය යවන්න. ඔබේ ඊමේල් පරීක්ෂා කරන්න.";

    try {
      final result = await _authService.resetPassword(
          email: _emailController.text.trim());

      if (!mounted) return;
      
      if (result == null) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(passwordSentText)),
        );
        // Navigate back to login page after success
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        HapticFeedback.vibrate();
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(result)));
      }
    } catch (e) {
      if (!mounted) return;
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An unexpected error occurred.")),
      );
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
    final String resetPasswordText =
        langProvider.currentLang == 'en' ? "Reset Password" : "මුරපදය යළි පිහිටුවන්න";
    final String enterEmailText =
        langProvider.currentLang == 'en' ? "Enter your email" : "ඔබේ ඊමේල් ඇතුළත් කරන්න";
    final String sendLinkText =
        langProvider.currentLang == 'en' ? "Send Reset Link" : "යළි පිහිටුම් සබැඳිය යවන්න";
    final String rememberPasswordText =
        langProvider.currentLang == 'en' ? "Remember your password? " : "මුරපදය මතක්ද? ";
    final String loginText = langProvider.currentLang == 'en' ? "Login" : "ඇතුළු වන්න";

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

          // Content
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
                      // Title
                      Text(
                        resetPasswordText,
                        style: GoogleFonts.poppins(
                          fontSize: isMobile ? 36 : 42,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 30),
                      
                      // Email Text Field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: customInputDecoration(enterEmailText),
                        validator: Validators.validateEmail,
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Submit Button
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
                          onPressed: loading ? null : _handlePasswordReset,
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
                                  sendLinkText,
                                  style: GoogleFonts.poppins(
                                    fontSize: isMobile ? 18 : 20,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.buttonText,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 30),
                    
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            rememberPasswordText,
                            style: GoogleFonts.roboto(color: AppColors.text),
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