import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/colors.dart';
import '../../constants/app_config.dart';
import '../../utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    final langProvider = Provider.of<LanguageProvider>(context);

    // Translations
    final loginText = langProvider.currentLang == 'en' ? "Login" : "ඇතුළු වන්න";
    final emailText = langProvider.currentLang == 'en' ? "Email" : "ඊමේල්";
    final passwordText = langProvider.currentLang == 'en' ? "Password" : "මුරපදය";
    final rememberMeText = langProvider.currentLang == 'en' ? "Remember Me" : "මතක් කරන්න";
    final forgotPasswordText =
        langProvider.currentLang == 'en' ? "Forgot Password?" : "මුරපදය අමතකද?";
    final dontHaveAccountText =
        langProvider.currentLang == 'en' ? "Don't have an account? " : "ගිණුමක් නැද්ද? ";
    final signUpText = langProvider.currentLang == 'en' ? "Sign Up" : "ලියාපදිංචි වන්න";

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
              // Background
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
                          // Language Dropdown
                          Align(
                            alignment: Alignment.centerRight,
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: langProvider.currentLang == 'en'
                                    ? "English"
                                    : "සිංහල",
                                items: const [
                                  DropdownMenuItem(
                                      value: "English", child: Text("English")),
                                  DropdownMenuItem(
                                      value: "සිංහල", child: Text("සිංහල")),
                                ],
                                onChanged: (val) {
                                  if (val == null) return;
                                  langProvider.setLanguage(
                                      val == "English" ? "en" : "si");
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            AppConfig.appName,
                            style: TextStyle(
                              fontSize: isMobile ? 32 : 36,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 20),

                          if (errorMessage != null)
                            Text(
                              errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          if (errorMessage != null) const SizedBox(height: 10),

                          // Email Field
                          TextFormField(
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
                            onSaved: (val) => email = val ?? '',
                          ),
                          const SizedBox(height: 20),

                          // Password Field
                          TextFormField(
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
                            onSaved: (val) => password = val ?? '',
                          ),
                          const SizedBox(height: 10),

                          Row(
                            children: [
                              Checkbox(
                                value: rememberMe,
                                onChanged: (val) =>
                                    setState(() => rememberMe = val ?? false),
                              ),
                              Text(rememberMeText),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Login Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: authProvider.isLoading
                                  ? null
                                  : () async {
                                      setState(() => errorMessage = null);
                                      if (_formKey.currentState!.validate()) {
                                        _formKey.currentState!.save();
                                        final result = await authProvider.login(
                                          email,
                                          password,
                                          rememberMe: rememberMe,
                                        );
                                        if (!mounted) return;

                                        if (result == null) {
                                          try {
                                            final uid = FirebaseAuth
                                                .instance.currentUser!.uid;
                                            final userDoc =
                                                await FirebaseFirestore.instance
                                                    .collection('users')
                                                    .doc(uid)
                                                    .get();

                                            final isComplete =
                                                userDoc.data()?[
                                                        'isUserRegistrationComplete'] ??
                                                    false;

                                            if (!isComplete) {
                                              Navigator.pushReplacement(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      UserRegistrationPage(
                                                          user: authProvider.user!),
                                                ),
                                              );
                                            } else {
                                              Navigator.pushReplacementNamed(
                                                  context, '/main-screen');
                                            }
                                          } catch (e) {
                                            setState(() => errorMessage =
                                                "Error loading user: $e");
                                          }
                                        } else {
                                          setState(() => errorMessage = result);
                                        }
                                      }
                                    },
                              child: authProvider.isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      loginText,
                                      style: TextStyle(
                                        fontSize: isMobile ? 16 : 18,
                                        color: AppColors.buttonText,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () =>
                                  Navigator.pushNamed(context, '/forgot-password'),
                              child: Text(
                                forgotPasswordText,
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                dontHaveAccountText,
                                style: const TextStyle(color: AppColors.text),
                              ),
                              GestureDetector(
                                onTap: () =>
                                    Navigator.pushNamed(context, '/signup'),
                                child: Text(
                                  signUpText,
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
      },
    );
  }
}
