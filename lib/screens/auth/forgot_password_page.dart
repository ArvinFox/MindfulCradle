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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t.auth('resetLinkSent'))),
        );
        // Navigate back to login page after success
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        HapticFeedback.vibrate();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result)));
      }
    } catch (e) {
      if (!mounted) return;
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t.auth('unexpectedError'))),
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
    final isSinhala = langProvider.currentLang == 'si';

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
            // Title
            Text(
              context.t.auth('resetPasswordTitle'),
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
