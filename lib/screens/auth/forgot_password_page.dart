import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/colors.dart';
import '../../utils/validators.dart';
import '../../utils/helpers.dart';
import '../../services/auth_service.dart';
import '../../providers/language_provider.dart';
import '../../widgets/auth/auth_primary_button.dart';
import '../../widgets/auth/auth_scaffold.dart';
import '../../widgets/auth/auth_language_toggle.dart';
import '../../utils/translate.dart';
import '../../utils/app_snackbar.dart';

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
  String? _lastLang;
  AutovalidateMode _autoValidateMode = AutovalidateMode.disabled;

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
    _emailController.dispose();
    super.dispose();
  }

  // Logic to handle password reset request
  Future<void> _handlePasswordReset() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.lightImpact();
      setState(() {
        _autoValidateMode = AutovalidateMode.onUserInteraction;
      });
      return;
    }

    setState(() => loading = true);

    // Translations for feedback
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final langCode = langProvider.currentLang;

    try {
      final result = await _authService.resetPassword(
        email: _emailController.text.trim(),
        langCode: langCode,
      );

      if (!mounted) return;

      if (result == null) {
        HapticFeedback.mediumImpact();
        AppSnackBar.success(context, context.t.auth('resetLinkSent'));
        // Navigate back to login page after success
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        HapticFeedback.vibrate();
        AppSnackBar.error(context, result);
      }
    } catch (e) {
      if (!mounted) return;
      HapticFeedback.vibrate();
      AppSnackBar.error(context, context.t.auth('unexpectedError'));
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
            // Title + description
            Text(
              context.t.auth('resetPasswordTitle'),
              style: GoogleFonts.poppins(
                fontSize: isMobile ? 28 : 34,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSinhala
                  ? 'ඔබේ ඊමේල් ලිපිනය ඇතුළු කරන්න, ඔබට නැවත සැකසීමේ සබැඳියක් යවනු ලැබේ.'
                  : "Enter your email and we'll send you a reset link.",
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: AppColors.textMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),

            // Email Text Field
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: customInputDecoration(context.t.auth('email')),
              validator: (val) =>
                  Validators.validateEmailLocalized(val, isSinhala: isSinhala),
            ),

            const SizedBox(height: 30),

            // Submit Button
            AuthPrimaryButton(
              text: context.t.auth('sendResetLink'),
              isLoading: loading,
              onPressed: loading ? null : _handlePasswordReset,
              fontSize: isMobile ? 18 : 20,
            ),
            const SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  context.t.auth('rememberPassword'),
                  style: GoogleFonts.roboto(color: AppColors.text),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context, '/login');
                  },
                  child: Text(
                    context.t.auth('login'),
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
