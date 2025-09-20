import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../utils/validators.dart';
import '../../services/auth_service.dart';

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

    return Scaffold(
      body: Stack(
        children: [
          // Background image
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
                      "Sign Up",
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
                        labelText: "Full Name",
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
                        labelText: "Email",
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
                        labelText: "Password",
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
                        labelText: "Confirm Password",
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
                                if (_formKey.currentState!.validate()) {
                                  setState(() => loading = true);

                                  final result = await _authService.signUp(
                                    email: _emailController.text.trim(),
                                    password: _passwordController.text.trim(),
                                    fullName: _fullNameController.text.trim(),
                                  );

                                  setState(() => loading = false);

                                  if (result == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Account created successfully! Please login.",
                                        ),
                                      ),
                                    );
                                    Navigator.pushReplacementNamed(
                                      context,
                                      '/login',
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(result)),
                                    );
                                  }
                                }
                              },
                        child: Text(
                          loading ? "Loading..." : "Sign Up",
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
                        const Text(
                          "Already have an account? ",
                          style: TextStyle(color: AppColors.text),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacementNamed(context, '/login');
                          },
                          child: Text(
                            "Login",
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
