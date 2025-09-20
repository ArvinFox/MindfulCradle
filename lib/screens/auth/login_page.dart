import 'package:flutter/material.dart';
import 'package:mamamind/constants/app_config.dart';
import '../../constants/colors.dart';
import '../../utils/validators.dart';
import '../../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';
  final AuthService _authService = AuthService();
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return Scaffold(
      body: Stack(
        children: [
          // Background image and fade overlay
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                  "assets/login/app_background.png",
                ),
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
                    const SizedBox(height: 30),

                    // Email
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

                    // Password
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
                    const SizedBox(height: 30),

                    // Login Button
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
                                  _formKey.currentState!.save();
                                  setState(() => loading = true);

                                  final result = await _authService.login(
                                    email: email,
                                    password: password,
                                  );

                                  setState(() => loading = false);

                                  if (result == null) {
                                    // Login success, navigate to home
                                    Navigator.pushReplacementNamed(
                                      context,
                                      '/main-screen',
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(result)),
                                    );
                                  }
                                }
                              },
                        child: Text(
                          loading ? "Loading..." : "Login",
                          style: TextStyle(
                            fontSize: isMobile ? 16 : 18,
                            color: AppColors.buttonText,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Forgot Password
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/forgot-password');
                        },
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

                    // Signup Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account? ",
                          style: TextStyle(color: AppColors.text),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, '/signup');
                          },
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
  }
}
