import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/colors.dart';
import '../../utils/validators.dart';
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final langProvider = Provider.of<LanguageProvider>(context);

    final String resetPasswordText =
        langProvider.currentLang == 'en' ? "Reset Password" : "මුරපදය යළි පිහිටුවන්න";
    final String enterEmailText =
        langProvider.currentLang == 'en' ? "Enter your email" : "ඔබේ ඊමේල් ඇතුළත් කරන්න";
    final String sendLinkText =
        langProvider.currentLang == 'en' ? "Send Reset Link" : "යළි පිහිටුම් සබැඳිය යවන්න";
    final String loadingText =
        langProvider.currentLang == 'en' ? "Loading..." : "පූරණය වෙමින්...";
    final String passwordSentText =
        langProvider.currentLang == 'en'
            ? "Password reset link sent! Check your email."
            : "මුරපදය යළි පිහිටුම් සබැඳිය යවන්න. ඔබේ ඊමේල් පරීක්ෂා කරන්න.";
    final String rememberPasswordText =
        langProvider.currentLang == 'en' ? "Remember your password? " : "මුරපදය මතක්ද? ";
    final String loginText = langProvider.currentLang == 'en' ? "Login" : "ඇතුළු වන්න";

    return Scaffold(
      body: Stack(
        children: [
          // Background image
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
          Center(
            child: Container(
              width: isMobile ? size.width * 0.9 : 400,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.background.withOpacity(0.85),
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 15,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      resetPasswordText,
                      style: TextStyle(
                        fontSize: isMobile ? 32 : 36,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Email
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.inputBackground,
                        labelText: enterEmailText,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.email),
                      ),
                      validator: Validators.validateEmail,
                    ),
                    const SizedBox(height: 30),
                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: loading
                            ? null
                            : () async {
                                if (_formKey.currentState!.validate()) {
                                  setState(() => loading = true);
                                  final result = await _authService.resetPassword(
                                      email: _emailController.text.trim());
                                  setState(() => loading = false);

                                  if (result == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(passwordSentText),
                                      ),
                                    );
                                    Navigator.pushReplacementNamed(context, '/login');
                                  } else {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(content: Text(result)));
                                  }
                                }
                              },
                        child: Text(
                          loading ? loadingText : sendLinkText,
                          style: TextStyle(
                            fontSize: isMobile ? 16 : 18,
                            color: AppColors.buttonText,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Back to Login
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          rememberPasswordText,
                          style: const TextStyle(color: AppColors.text),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacementNamed(context, '/login');
                          },
                          child: Text(
                            loginText,
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
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
        ],
      ),
    );
  }
}
