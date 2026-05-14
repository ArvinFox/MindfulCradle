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
import '../../utils/translate.dart';
import '../../utils/app_snackbar.dart';

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

    // Guard against widget disposal during the dialog
    if (!mounted) return;

    if (consent == null || !consent) {
      // User declined consent - stay on signup
      HapticFeedback.vibrate();
      AppSnackBar.info(
        context,
        langCode == 'si'
            ? 'ඉදිරියට යාම සඳහා දත්ත කැමැත්ත අවශ්‍යයි.'
            : 'Consent is required to continue.',
      );
      return;
    }

    // User accepted consent - proceed with signup
    setState(() => loading = true);

    // Capture values before async gap
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final fullName = _fullNameController.text.trim();

    String? result;
    try {
      result = await _authService.signUp(
        email: email,
        password: password,
        fullName: fullName,
        langCode: langCode,
      );
    } catch (e) {
      result = langCode == 'si'
          ? 'අනපේක්ෂිත දෝෂයක් සිදු විය. නැවත උත්සාහ කරන්න.'
          : 'An unexpected error occurred. Please try again.';
    }

    if (!mounted) return;
    setState(() => loading = false);

    if (result == null) {
      // Success feedback
      HapticFeedback.mediumImpact();

      AppSnackBar.success(context, context.t.auth('accountCreated'));

      _fullNameController.clear();
      _emailController.clear();
      _passwordController.clear();
      _confirmController.clear();

      Navigator.pushReplacementNamed(context, '/login');
    } else {
      // Error feedback
      HapticFeedback.vibrate();
      AppSnackBar.error(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final isMobile = width < 600;
    final isCompact = width < 380;

    final langProvider = Provider.of<LanguageProvider>(context);
    final isSinhala = langProvider.currentLang == 'si';

    return AuthScaffold(
      child: Form(
        key: _formKey,
        autovalidateMode: _autoValidateMode,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Branding + Language row
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.heroGradientStart,
                        AppColors.heroGradientMid,
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.28),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.spa_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Mindful Cradle',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const Spacer(),
                const AuthLanguageToggle(),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              context.t.auth('signUp'),
              style: GoogleFonts.poppins(
                fontSize: isMobile ? (width * 0.085).clamp(26.0, 32.0) : 34,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isSinhala ? 'නව ගිණුමක් සාදන්න' : 'Create your account',
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: AppColors.textMuted,
              ),
            ),
            SizedBox(height: isCompact ? 16 : 24),

            // Full Name
            TextFormField(
              controller: _fullNameController,
              keyboardType: TextInputType.name,
              inputFormatters: [
                FilteringTextInputFormatter.deny(RegExp(r'[\r\n\t]')),
                LengthLimitingTextInputFormatter(60),
              ],
              decoration: customInputDecoration(context.t.auth('fullName'))
                  .copyWith(
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
              decoration: customInputDecoration(context.t.auth('email'))
                  .copyWith(
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
              decoration: customInputDecoration(context.t.auth('password'))
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
                        color: AppColors.text.withValues(alpha: 0.6),
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
              decoration:
                  customInputDecoration(
                    context.t.auth('confirmPassword'),
                  ).copyWith(
                    prefixIcon: const Icon(
                      Icons.lock_reset,
                      color: AppColors.primary,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        isConfirmPasswordVisible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.text.withValues(alpha: 0.6),
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
              text: context.t.auth('signUp'),
              isLoading: loading,
              onPressed: loading ? null : _handleSignup,
              fontSize: isMobile ? 18 : 20,
            ),
            SizedBox(height: isCompact ? 20 : 28),
            // Login Link
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              runSpacing: 2,
              children: [
                Text(
                  context.t.auth('alreadyHaveAccount'),
                  style: GoogleFonts.roboto(
                    color: AppColors.text,
                    fontSize: isCompact ? 13 : 14,
                  ), // Using Roboto font
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context, '/login');
                  },
                  child: Text(
                    context.t.auth('login'),
                    style: GoogleFonts.roboto(
                      color: AppColors.primary,
                      fontSize: isCompact ? 13 : 14,
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
