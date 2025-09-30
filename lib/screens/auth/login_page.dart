import 'package:flutter/material.dart';
import 'package:mamamind/screens/auth/user_registration_page.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/colors.dart';
import '../../constants/app_config.dart';
import '../../utils/validators.dart';
import '../../providers/auth_provider.dart';

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
                            labelText: "Email",
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
                            labelText: "Password",
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
                            const Text("Remember Me"),
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
                                          // ✅ Fetch the latest user doc from Firestore
                                          final uid = FirebaseAuth
                                              .instance.currentUser!.uid;
                                          final userDoc =
                                              await FirebaseFirestore.instance
                                                  .collection('users')
                                                  .doc(uid)
                                                  .get();

                                          final isComplete = userDoc
                                                  .data()?[
                                                      'isUserRegistrationComplete'] ??
                                              false;

                                          if (!isComplete) {
                                            // Go to registration page
                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    UserRegistrationPage(
                                                  user: authProvider.user!,
                                                ),
                                              ),
                                            );
                                          } else {
                                            // Go to main screen
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
                                    "Login",
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
                            onTap: () => Navigator.pushNamed(
                              context,
                              '/forgot-password',
                            ),
                            child: Text(
                              "Forgot Password?",
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
                            const Text(
                              "Don't have an account? ",
                              style: TextStyle(color: AppColors.text),
                            ),
                            GestureDetector(
                              onTap: () =>
                                  Navigator.pushNamed(context, '/signup'),
                              child: Text(
                                "Sign Up",
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
      },
    );
  }
}
