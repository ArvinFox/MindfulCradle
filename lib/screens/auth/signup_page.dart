import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/colors.dart';
import '../../utils/validators.dart';
import '../../services/auth_service.dart';
import '../../utils/helpers.dart';
import '../../providers/language_provider.dart';
import '../../widgets/auth/auth_primary_button.dart';
import '../../widgets/auth/auth_scaffold.dart';
import '../../widgets/auth/auth_language_toggle.dart';
import '../../widgets/auth/consent_dialog.dart';

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
  String? _lastLang;
  AutovalidateMode _autoValidateMode = AutovalidateMode.disabled;

  final AuthService _authService = AuthService();
  bool loading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final lang = Provider.of<LanguageProvider>(context).currentLang;
    if (_lastLang != null && _lastLang != lang) {
      if (_autoValidateMode != AutovalidateMode.disabled) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _formKey.currentState?.validate();
        });
      }
    }
    _lastLang = lang;
  }

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
      setState(() {
        _autoValidateMode = AutovalidateMode.onUserInteraction;
      });
      return;
    }

    final langCode = Provider.of<LanguageProvider>(
      context,
      listen: false,
    ).currentLang;

    // Show GDPR consent dialog
    final consent = await ConsentDialog.show(context, langCode);

    if (consent == null || !consent) {
      // User declined consent - stay on signup
      HapticFeedback.vibrate();
      final exitMessage = langCode == 'si'
          ? 'ඉදිරියට යාම සඳහා දත්ත කැමැත්ත අවශ්‍යයි.'
          : 'Consent is required to continue.';

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(exitMessage)));
      }
      return;
    }

    // User accepted consent - proceed with signup
    setState(() => loading = true);

    try {
      final result = await _authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        fullName: _fullNameController.text.trim(),
        langCode: langCode,
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
      final fallbackText = langCode == 'si'
          ? 'නොසිතු දෝෂයක් සිදු විය.'
          : 'An unexpected error occurred.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(fallbackText)));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    final langProvider = Provider.of<LanguageProvider>(context);
    final isSinhala = langProvider.currentLang == 'si';

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

    return AuthScaffold(
      child: Form(
        key: _formKey,
        autovalidateMode: _autoValidateMode,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Align(
              alignment: Alignment.centerRight,
              child: AuthLanguageToggle(),
            ),
            const SizedBox(height: 15),
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
              inputFormatters: [
                FilteringTextInputFormatter.deny(RegExp(r'[\r\n\t]')),
                LengthLimitingTextInputFormatter(60),
              ],
              decoration: customInputDecoration(fullNameText).copyWith(
                prefixIcon: const Icon(
                  Icons.person_outline,
                  color: AppColors.primary,
                ),
              ),
              validator: (val) =>
                  Validators.validateNameLocalized(val, isSinhala: isSinhala),
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
              validator: (val) =>
                  Validators.validateEmailLocalized(val, isSinhala: isSinhala),
            ),
            const SizedBox(height: 20),

            // Password
            TextFormField(
              controller: _passwordController,
              obscureText: !isPasswordVisible,
              decoration: customInputDecoration(passwordText).copyWith(
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
              validator: (val) => Validators.validatePasswordLocalized(
                val,
                isSinhala: isSinhala,
              ),
            ),
            const SizedBox(height: 20),

            // Confirm Password
            TextFormField(
              controller: _confirmController,
              obscureText: !isConfirmPasswordVisible,
              decoration: customInputDecoration(confirmPasswordText).copyWith(
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
                      isConfirmPasswordVisible = !isConfirmPasswordVisible;
                    });
                  },
                ),
              ),
              validator: (val) => Validators.validateConfirmPasswordLocalized(
                _passwordController.text,
                val,
                isSinhala: isSinhala,
              ),
            ),
            const SizedBox(height: 30),

            // Signup Button
            AuthPrimaryButton(
              text: signUpText,
              isLoading: loading,
              onPressed: loading ? null : _handleSignup,
              fontSize: isMobile ? 18 : 20,
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
    );
  }
}
