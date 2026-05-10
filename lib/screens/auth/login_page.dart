import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/colors.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../utils/validators.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../utils/helpers.dart';
import 'user_registration_page.dart';
import '../../widgets/auth/auth_primary_button.dart';
import '../../widgets/auth/auth_scaffold.dart';
import '../../widgets/auth/consent_dialog.dart';
import '../../utils/app_snackbar.dart';
import '../../utils/translate.dart';

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
  bool isPasswordVisible = false;
  String? _lastLang;
  AutovalidateMode _autoValidateMode = AutovalidateMode.disabled;

  static const String _authFailedEn =
      'Authentication failed. Please try again.';
  static const String _authFailedSi =
      'සත්‍යාපනය අසාර්ථකයි. කරුණාකර නැවත උත්සාහ කරන්න.';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final lang = Provider.of<LanguageProvider>(context).currentLang;
    if (_lastLang != null && _lastLang != lang) {
      if (errorMessage == _authFailedEn || errorMessage == _authFailedSi) {
        errorMessage = lang == 'si' ? _authFailedSi : _authFailedEn;
      }
      if (_autoValidateMode != AutovalidateMode.disabled) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _formKey.currentState?.validate();
        });
      }
    }
    _lastLang = lang;
  }

  Future<void> _handleLogin(
    BuildContext context,
    AuthProvider authProvider, {
    required String langCode,
  }) async {
    setState(() => errorMessage = null);
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.lightImpact();
      setState(() {
        _autoValidateMode = AutovalidateMode.onUserInteraction;
      });
      return;
    }
    _formKey.currentState!.save();

    final result = await authProvider.login(
      email,
      password,
      rememberMe: rememberMe,
      langCode: langCode,
    );

    if (!mounted) return;

    if (result == null) {
      HapticFeedback.mediumImpact();
      await _routeAfterSuccessfulLogin(authProvider);
    } else {
      HapticFeedback.vibrate();
      setState(() => errorMessage = result);
    }
  }

  Future<void> _handleGoogleLogin(
    BuildContext context,
    AuthProvider authProvider, {
    required String langCode,
  }) async {
    setState(() => errorMessage = null);

    final result = await authProvider.loginWithGoogle(
      rememberMe: rememberMe,
      langCode: langCode,
    );

    if (!mounted) return;

    // ── Error from Google/Firebase auth ──────────────────────────────────
    if (result.error != null) {
      HapticFeedback.vibrate();
      setState(() => errorMessage = result.error);
      return;
    }

    // ── Brand-new user — must accept the privacy policy before proceeding ──
    if (result.isNewUser) {
      final consent = await ConsentDialog.show(context, langCode);
      if (!mounted) return;

      if (consent != true) {
        // Declined — sign out (Firebase auth user exists but no Firestore doc,
        // so next sign-in attempt will ask for consent again).
        await authProvider.logout();
        if (!mounted) return;
        HapticFeedback.vibrate();
        AppSnackBar.info(
          context,
          context.t.auth('consentRequiredGoogle'),
        );
        return;
      }

      // Accepted — create the Firestore document now.
      await authProvider.completeGoogleSignUp(rememberMe: rememberMe);
      if (!mounted) return;
    }

    HapticFeedback.mediumImpact();
    await _routeAfterSuccessfulLogin(authProvider);
  }

  Future<void> _routeAfterSuccessfulLogin(AuthProvider authProvider) async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      final data = userDoc.data();
      if (data == null) {
        setState(() {
          errorMessage = context.t.auth('userDataNotFound');
        });
        return;
      }

      final isComplete = data['isUserRegistrationComplete'] ?? false;

      if (!isComplete) {
        final localUser = authProvider.user ?? UserModel.fromMap(data, uid);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => UserRegistrationPage(user: localUser),
          ),
        );
      } else {
        Navigator.pushReplacementNamed(context, '/main-screen');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = context.t.auth('errorLoadingUserData');
      });
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

    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.isInitializing) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.inputBackground.withValues(
                          alpha: 0.30,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.30),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: context.t.common(
                            context.isEnglish ? 'english' : 'sinhala',
                          ),
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            color: AppColors.text,
                            fontWeight: FontWeight.w500,
                          ),
                          iconEnabledColor: AppColors.text,
                          items: [
                            DropdownMenuItem(
                              value: context.t.common('english'),
                              child: Text(
                                context.t.common('english'),
                                style: const TextStyle(color: AppColors.text),
                              ),
                            ),
                            DropdownMenuItem(
                              value: context.t.common('sinhala'),
                              child: Text(
                                context.t.common('sinhala'),
                                style: const TextStyle(color: AppColors.text),
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            if (val == null) return;
                            langProvider.setLanguage(
                              val == context.t.common('english') ? 'en' : 'si',
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Title + subtitle
                Text(
                  context.t.auth('login'),
                  style: GoogleFonts.poppins(
                    fontSize: isMobile ? (width * 0.085).clamp(26.0, 32.0) : 34,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isSinhala
                      ? 'ඔබේ ගිණුමට ලොග් වන්න'
                      : 'Sign in to your account',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: AppColors.textMuted,
                  ),
                ),
                SizedBox(height: isCompact ? 20 : 28),

                // Error Message
                if (errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: Text(
                      errorMessage!,
                      style: GoogleFonts.roboto(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Email Field
                TextFormField(
                  keyboardType: TextInputType.emailAddress,
                  decoration: customInputDecoration(context.t.auth('email'))
                      .copyWith(
                        prefixIcon: const Icon(
                          Icons.email_outlined,
                          color: AppColors.primary,
                        ),
                      ),
                  validator: (val) => Validators.validateEmailLocalized(
                    val,
                    isSinhala: isSinhala,
                  ),
                  onSaved: (val) => email = val ?? '',
                ),
                const SizedBox(height: 20),

                // Password Field
                TextFormField(
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
                  onSaved: (val) => password = val ?? '',
                ),
                const SizedBox(height: 12),

                // Remember Me & Forgot Password (Fixed with Row)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => rememberMe = !rememberMe),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Checkbox(
                            value: rememberMe,
                            visualDensity: isCompact
                                ? const VisualDensity(
                                    horizontal: -2,
                                    vertical: -2,
                                  )
                                : VisualDensity.standard,
                            onChanged: (val) =>
                                setState(() => rememberMe = val ?? false),
                            activeColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          Text(
                            context.t.auth('rememberMe'),
                            style: GoogleFonts.roboto(
                              fontSize: isCompact ? 13 : 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.text.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () =>
                          Navigator.pushNamed(context, '/forgot-password'),
                      child: Text(
                        context.t.auth('forgotPassword'),
                        style: GoogleFonts.roboto(
                          color: AppColors.primary,
                          fontSize: isCompact ? 13 : 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isCompact ? 24 : 32),

                // Login Button
                AuthPrimaryButton(
                  text: context.t.auth('login'),
                  isLoading: authProvider.isLoading,
                  onPressed: authProvider.isLoading
                      ? null
                      : () => _handleLogin(
                          context,
                          authProvider,
                          langCode: langProvider.currentLang,
                        ),
                  fontSize: isMobile ? 18 : 20,
                ),
                const SizedBox(height: 24),

                // Divider Line
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: AppColors.text.withValues(alpha: 0.30),
                        thickness: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        context.t.auth('or'),
                        style: GoogleFonts.roboto(
                          color: AppColors.text.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: AppColors.text.withValues(alpha: 0.30),
                        thickness: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Custom Google Sign-In Button (Perfectly Centered)
                SizedBox(
                  width: double.infinity,
                  height: isMobile ? 54 : 58,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      side: BorderSide(
                        color: AppColors.text.withValues(alpha: 0.30),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      if (authProvider.isLoading) return;
                      _handleGoogleLogin(
                        context,
                        authProvider,
                        langCode: langProvider.currentLang,
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/login/google_logo.svg',
                          height: 24,
                          width: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          context.t.auth('continueWithGoogle'),
                          style: GoogleFonts.roboto(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Sign Up Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${context.t.auth('dontHaveAccount')} ',
                      style: GoogleFonts.roboto(
                        color: AppColors.text.withValues(alpha: 0.8),
                        fontSize: isCompact ? 13 : 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/signup'),
                      child: Text(
                        context.t.auth('signUp'),
                        style: GoogleFonts.roboto(
                          color: AppColors.primary,
                          fontSize: isCompact ? 13 : 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
