import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/colors.dart';
import '../../widgets/gradient_button.dart';
import '../../models/user_model.dart';
import '../../utils/helpers.dart';
import '../../utils/app_snackbar.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../utils/translate.dart';
import '../../services/localization_service.dart';
import '../../widgets/app_background.dart';

class UserRegistrationPage extends StatefulWidget {
  final UserModel user;

  const UserRegistrationPage({super.key, required this.user});

  @override
  State<UserRegistrationPage> createState() => _UserRegistrationPageState();
}

class _UserRegistrationPageState extends State<UserRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  // Page 1 fields
  late TextEditingController ageController;
  late TextEditingController residenceController;

  // Page 2 fields
  String pregnancyMonth = '';
  bool firstTimeMother = false;
  bool employed = false;
  bool obstetricComplication = false;
  bool psychologicalSupport = false;
  bool distressingEvents = false;
  bool practicedMindfulness = false;
  String mindfulnessDuration = '';

  bool _isSaving = false;
  DateTime? lastBackPressTime;

  @override
  void initState() {
    super.initState();
    ageController = TextEditingController();
    residenceController = TextEditingController();
  }

  @override
  void dispose() {
    ageController.dispose();
    residenceController.dispose();
    super.dispose();
  }

  // checkbox
  Widget _buildCheckbox(
    String title,
    bool value,
    void Function(bool) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: (val) => onChanged(val ?? false),
            activeColor: AppColors.primary,
            side: const BorderSide(color: AppColors.text, width: 1.5),
          ),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.roboto(fontSize: 15, color: AppColors.text),
            ),
          ),
        ],
      ),
    );
  }

  // Stacked label-above-value item — eliminates line-break alignment issues
  Widget _buildConfItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: GoogleFonts.roboto(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }

  // --- Logic Functions ---

  Future<void> _saveToFirebase() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    final userDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.user.id);

    // Map mindfulness durations to English values for storage
    final mindfulnessMap = {
      LocalizationService.instance.auth('lessThan1Month', 'en'):
          'Less than 1 month',
      LocalizationService.instance.auth('lessThan1Month', 'si'):
          'Less than 1 month',
      LocalizationService.instance.auth('1month', 'en'): '1 Month',
      LocalizationService.instance.auth('1month', 'si'): '1 Month',
      LocalizationService.instance.auth('2month', 'en'): '2 Months',
      LocalizationService.instance.auth('2month', 'si'): '2 Months',
      LocalizationService.instance.auth('3month', 'en'): '3 Months',
      LocalizationService.instance.auth('3month', 'si'): '3 Months',
      LocalizationService.instance.auth('4month', 'en'): '4 Months',
      LocalizationService.instance.auth('4month', 'si'): '4 Months',
      LocalizationService.instance.auth('5month', 'en'): '5 Months',
      LocalizationService.instance.auth('5month', 'si'): '5 Months',
      LocalizationService.instance.auth('moreThan6Months', 'en'):
          'More than 6 months',
      LocalizationService.instance.auth('moreThan6Months', 'si'):
          'More than 6 months',
    };

    final mindfulnessToSave = practicedMindfulness
        ? mindfulnessMap[mindfulnessDuration] ?? ''
        : null;

    // Perform all async/Firestore/prefs work WITHOUT touching BuildContext
    // inside the try-catch. Any exception thrown here will be stored and
    // handled after the finally block, avoiding silent swallowing of errors
    // that previously caused the "nothing happens" intermittent bug.
    Object? saveError;
    try {
      await userDoc.set({
        'age': int.tryParse(ageController.text) ?? 0,
        'residence': residenceController.text.trim(),
        'pregnancyMonth': pregnancyMonth,
        'firstTimeMother': firstTimeMother,
        'employed': employed,
        'obstetricComplication': obstetricComplication,
        'psychologicalSupport': psychologicalSupport,
        'distressingEvents': distressingEvents,
        'practicedMindfulness': practicedMindfulness,
        'mindfulnessDuration': mindfulnessToSave,
        'isUserRegistrationComplete': true,
        'isTutorialDone': false,
        'registrationDate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Prefs writes — also inside try so they're rolled back on failure
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('tutorial_done', false);
      await prefs.setBool('skip_mood_prompt_once', true);
    } catch (e) {
      saveError = e;
    } finally {
      // Reset loading state unconditionally so the button is always re-enabled
      if (mounted) setState(() => _isSaving = false);
    }

    // All async work is done. Now use BuildContext safely — one mounted check,
    // no more async gaps, no risk of exceptions silently stopping navigation.
    if (!mounted) return;

    if (saveError != null) {
      HapticFeedback.vibrate();
      AppSnackBar.error(
        context,
        context.t.auth('saveError') + saveError.toString(),
      );
      return;
    }

    // Navigate to main screen — the coach-mark tutorial will automatically
    // appear as an overlay once MainScreen detects tutorial_done = false.
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil('/main-screen', (route) => false);
  }

  void _showConfirmationDialog() {
    String yesNo(bool value) =>
        value ? context.t.auth('yes') : context.t.auth('no');
    final width = MediaQuery.of(context).size.width;
    final compact = width < 380;

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: width < 720 ? width - 24 : 640,
              maxHeight: MediaQuery.of(ctx).size.height * 0.82,
            ),
            child: Container(
              padding: EdgeInsets.all(compact ? 14 : 18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    context.t.auth('confirmDetails'),
                    style: GoogleFonts.poppins(
                      fontSize: compact ? 17 : 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildConfItem(
                            context.t.auth('age'),
                            ageController.text,
                          ),
                          const SizedBox(height: 8),
                          _buildConfItem(
                            context.t.auth('residence'),
                            residenceController.text,
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              context.t.auth('pregnancyInfo').toUpperCase(),
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          _buildConfItem(
                            context.t.auth('pregnancyMonth'),
                            pregnancyMonth,
                          ),
                          const SizedBox(height: 8),
                          _buildConfItem(
                            context.t.auth('firstTimeMother'),
                            yesNo(firstTimeMother),
                          ),
                          const SizedBox(height: 8),
                          _buildConfItem(
                            context.t.auth('employed'),
                            yesNo(employed),
                          ),
                          const SizedBox(height: 8),
                          _buildConfItem(
                            context.t.auth('obstetricComplication'),
                            yesNo(obstetricComplication),
                          ),
                          const SizedBox(height: 8),
                          _buildConfItem(
                            context.t.auth('psychologicalSupport'),
                            yesNo(psychologicalSupport),
                          ),
                          const SizedBox(height: 8),
                          _buildConfItem(
                            context.t.auth('distressingEvents'),
                            yesNo(distressingEvents),
                          ),
                          const SizedBox(height: 8),
                          _buildConfItem(
                            context.t.auth('practicedMindfulness'),
                            yesNo(practicedMindfulness),
                          ),
                          if (practicedMindfulness) ...[
                            const SizedBox(height: 8),
                            _buildConfItem(
                              context.t.auth('mindfulnessDuration'),
                              mindfulnessDuration,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.text,
                            padding: EdgeInsets.symmetric(
                              vertical: compact ? 12 : 14,
                            ),
                            side: const BorderSide(
                              color: AppColors.primary,
                              width: 1.3,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(
                            context.t.auth('cancel'),
                            style: GoogleFonts.roboto(
                              fontSize: compact ? 14 : 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GradientButton(
                          padding: EdgeInsets.symmetric(
                            vertical: compact ? 12 : 14,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await _saveToFirebase();
                          },
                          child: _isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  context.t.auth('confirm'),
                                  style: GoogleFonts.roboto(
                                    fontSize: compact ? 14 : 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- Page Builder Functions ---

  Widget _buildPage1(BuildContext context, bool isMobile) {
    final isCompact = MediaQuery.of(context).size.width < 380;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Page Title
        Text(
          context.t.auth('basicInfo'),
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: isMobile ? (isCompact ? 28 : 32) : 36,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        SizedBox(height: isCompact ? 20 : 26),

        TextFormField(
          controller: ageController,
          decoration: customInputDecoration(context.t.auth('age')),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(2),
          ],
          validator: (val) {
            if (val == null || val.isEmpty) return context.t.auth('required');
            final numValue = int.tryParse(val);
            if (numValue == null) return context.t.auth('mustNumber');
            if (numValue < 18 || numValue > 70) {
              return context.t.auth('ageLimit');
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: residenceController,
          decoration: customInputDecoration(context.t.auth('residence')),
          inputFormatters: [
            FilteringTextInputFormatter.deny(RegExp(r'[\r\n\t]')),
            LengthLimitingTextInputFormatter(80),
          ],
          validator: (val) =>
              val == null || val.isEmpty ? context.t.auth('required') : null,
        ),
        const SizedBox(height: 30),

        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            GradientButton(
              onPressed: _isSaving
                  ? null
                  : () {
                      HapticFeedback.lightImpact();
                      if (_formKey.currentState!.validate()) {
                        setState(() => _currentStep = 1);
                      }
                    },
              padding: EdgeInsets.symmetric(
                vertical: isCompact ? 14 : 16,
                horizontal: isCompact ? 24 : 32,
              ),
              borderRadius: BorderRadius.circular(15),
              child: Text(
                context.t.auth('next'),
                style: GoogleFonts.roboto(
                  fontSize: isMobile ? 18 : 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPage2(BuildContext context, bool isMobile, bool isSinhala) {
    final isCompact = MediaQuery.of(context).size.width < 380;
    final durationOptions = [
      context.t.auth('lessThan1Month'),
      context.t.auth('1month'),
      context.t.auth('2month'),
      context.t.auth('3month'),
      context.t.auth('4month'),
      context.t.auth('5month'),
      context.t.auth('moreThan6Months'),
    ];

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Page Title
          Text(
            context.t.auth('pregnancyInfo'),
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: isMobile ? (isCompact ? 28 : 32) : 36,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: isCompact ? 20 : 26),

          // Pregnancy Month Dropdown
          DropdownButtonFormField<String>(
            initialValue: pregnancyMonth.isEmpty ? null : pregnancyMonth,
            decoration: customInputDecoration(context.t.auth('pregnancyMonth')),
            items: List.generate(9, (index) {
              final monthValue = index + 1;
              final monthLabel = isSinhala
                  ? context.t.auth('month')
                  : (monthValue == 1 ? 'month' : 'months');
              return DropdownMenuItem(
                value: '$monthValue',
                child: Text(
                  '$monthValue $monthLabel',
                  style: GoogleFonts.roboto(color: AppColors.text),
                ),
              );
            }),
            onChanged: (val) => setState(() => pregnancyMonth = val ?? ''),
            validator: (val) =>
                val == null || val.isEmpty ? context.t.auth('required') : null,
          ),
          const SizedBox(height: 20),

          // Checkboxes
          _buildCheckbox(context.t.auth('firstTimeMother'), firstTimeMother, (
            val,
          ) {
            setState(() => firstTimeMother = val);
          }),
          _buildCheckbox(context.t.auth('employed'), employed, (val) {
            setState(() => employed = val);
          }),
          _buildCheckbox(
            context.t.auth('obstetricComplication'),
            obstetricComplication,
            (val) {
              setState(() => obstetricComplication = val);
            },
          ),
          _buildCheckbox(
            context.t.auth('psychologicalSupport'),
            psychologicalSupport,
            (val) {
              setState(() => psychologicalSupport = val);
            },
          ),
          _buildCheckbox(
            context.t.auth('distressingEvents'),
            distressingEvents,
            (val) {
              setState(() => distressingEvents = val);
            },
          ),
          _buildCheckbox(
            context.t.auth('practicedMindfulness'),
            practicedMindfulness,
            (val) {
              setState(() => practicedMindfulness = val);
              if (!val) {
                mindfulnessDuration = '';
              } // Reset duration if unchecked
            },
          ),
          const SizedBox(height: 10),

          // Mindfulness Duration Dropdown
          if (practicedMindfulness)
            Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: DropdownButtonFormField<String>(
                initialValue: mindfulnessDuration.isEmpty
                    ? null
                    : mindfulnessDuration,
                decoration: customInputDecoration(
                  context.t.auth('mindfulnessDuration'),
                ),
                items: durationOptions
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(
                          e,
                          style: GoogleFonts.roboto(color: AppColors.text),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (val) =>
                    setState(() => mindfulnessDuration = val ?? ''),
                validator: (val) =>
                    practicedMindfulness && (val == null || val.isEmpty)
                    ? context.t.auth('required')
                    : null,
              ),
            ),
          const SizedBox(height: 30),

          // Navigation Buttons
          Row(
            children: [
              OutlinedButton(
                onPressed: _isSaving
                    ? null
                    : () {
                        HapticFeedback.lightImpact();
                        setState(() => _currentStep = 0);
                      },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.text,
                  padding: EdgeInsets.symmetric(
                    vertical: isCompact ? 14 : 16,
                    horizontal: isCompact ? 16 : 24,
                  ),
                  side: const BorderSide(color: AppColors.text, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: Text(
                  context.t.auth('back'),
                  style: GoogleFonts.roboto(
                    fontSize: isMobile ? 18 : 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              GradientButton(
                onPressed: _isSaving
                    ? null
                    : () {
                        HapticFeedback.mediumImpact();
                        if (_formKey.currentState!.validate()) {
                          setState(() {});
                          _showConfirmationDialog();
                        }
                      },
                padding: EdgeInsets.symmetric(
                  vertical: isCompact ? 14 : 16,
                  horizontal: isCompact ? 24 : 32,
                ),
                borderRadius: BorderRadius.circular(15),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        context.t.auth('finish'),
                        style: GoogleFonts.roboto(
                          fontSize: isMobile ? 18 : 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Main Build Method ---

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final langProvider = Provider.of<LanguageProvider>(context);
    final isSinhala = langProvider.currentLang == 'si';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_currentStep == 1) {
          HapticFeedback.lightImpact();
          setState(() => _currentStep = 0);
          return;
        }

        DateTime now = DateTime.now();
        if (lastBackPressTime == null ||
            now.difference(lastBackPressTime!) > const Duration(seconds: 2)) {
          lastBackPressTime = now;
          AppSnackBar.info(
            context,
            context.t.auth('exitRegistrationMessage'),
            duration: const Duration(seconds: 2),
          );
          return;
        }
        // LoginPage was replaced (pushReplacement), so popping leads to a
        // black screen. Instead sign the user out and go back to login.
        if (mounted) {
          final auth = context.read<AuthProvider>();
          await auth.logout();
          Navigator.pushReplacementNamed(context, '/login');
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: AppBackground(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: Container(
                width: isMobile ? size.width * 0.92 : 520,
                padding: EdgeInsets.all(isMobile ? 20 : 28),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Language toggle row (same logic as login page)
                    Row(
                      children: [
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
                                    style: const TextStyle(
                                      color: AppColors.text,
                                    ),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: context.t.common('sinhala'),
                                  child: Text(
                                    context.t.common('sinhala'),
                                    style: const TextStyle(
                                      color: AppColors.text,
                                    ),
                                  ),
                                ),
                              ],
                              onChanged: (val) {
                                if (val == null) return;
                                langProvider.setLanguage(
                                  val == context.t.common('english')
                                      ? 'en'
                                      : 'si',
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Form(
                      key: _formKey,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _currentStep == 0
                            ? _buildPage1(context, isMobile)
                            : _buildPage2(context, isMobile, isSinhala),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
