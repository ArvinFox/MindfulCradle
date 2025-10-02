import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/colors.dart';
import '../../utils/validators.dart';
import '../../services/auth_service.dart';
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    final langProvider = Provider.of<LanguageProvider>(context);

    // Translations
    final signUpText = langProvider.currentLang == 'en' ? "Sign Up" : "ලියාපදිංචි වන්න";
    final fullNameText = langProvider.currentLang == 'en' ? "Full Name" : "සම්පූර්ණ නම";
    final emailText = langProvider.currentLang == 'en' ? "Email" : "ඊමේල්";
    final passwordText = langProvider.currentLang == 'en' ? "Password" : "මුරපදය";
    final confirmPasswordText = langProvider.currentLang == 'en' ? "Confirm Password" : "මුරපදය තහවුරු කරන්න";
    final accountCreatedText = langProvider.currentLang == 'en'
        ? "Account created successfully! Please login."
        : "ගිණුම සාර්ථකව සෑදන ලදි! කරුණාකර ඇතුළු වන්න.";
    final alreadyHaveAccountText = langProvider.currentLang == 'en'
        ? "Already have an account? "
        : "දැනටම ගිණුමක් තිබේද? ";
    final loginText = langProvider.currentLang == 'en' ? "Login" : "ඇතුළු වන්න";

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
            child: SingleChildScrollView(
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
                        signUpText,
                        style: TextStyle(
                          fontSize: isMobile ? 32 : 36,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Full Name
                      TextFormField(
                        controller: _fullNameController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.inputBackground,
                          labelText: fullNameText,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.person),
                        ),
                        validator: Validators.validateName,
                      ),
                      const SizedBox(height: 20),

                      // Email
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.inputBackground,
                          labelText: emailText,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.email),
                        ),
                        validator: Validators.validateEmail,
                      ),
                      const SizedBox(height: 20),

                      // Password
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.inputBackground,
                          labelText: passwordText,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.lock),
                        ),
                        validator: Validators.validatePassword,
                      ),
                      const SizedBox(height: 20),

                      // Confirm Password
                      TextFormField(
                        controller: _confirmController,
                        obscureText: true,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.inputBackground,
                          labelText: confirmPasswordText,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.lock_outline),
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
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: loading
                              ? null
                              : () async {
                                  if (!_formKey.currentState!.validate()) return;

                                  setState(() => loading = true);

                                  try {
                                    final result = await _authService.signUp(
                                      email: _emailController.text.trim(),
                                      password: _passwordController.text.trim(),
                                      fullName: _fullNameController.text.trim(),
                                    );

                                    if (result == null) {
                                      if (!mounted) return;

                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(accountCreatedText)),
                                      );

                                      _fullNameController.clear();
                                      _emailController.clear();
                                      _passwordController.clear();
                                      _confirmController.clear();

                                      Navigator.pushReplacementNamed(context, '/login');
                                    } else {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(result)),
                                      );
                                    }
                                  } catch (e) {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(e.toString())),
                                    );
                                  } finally {
                                    if (mounted) setState(() => loading = false);
                                  }
                                },
                          child: loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  signUpText,
                                  style: TextStyle(
                                    fontSize: isMobile ? 16 : 18,
                                    color: AppColors.buttonText,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Login Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            alreadyHaveAccountText,
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
          ),
        ],
      ),
    );
  }
}
