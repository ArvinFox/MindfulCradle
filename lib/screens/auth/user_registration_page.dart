import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/colors.dart';
import '../../models/user_model.dart';
import '../../utils/helpers.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../utils/translate.dart';
import '../../services/localization_service.dart';

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

  // confirmation dialog
  Widget _buildConfRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.roboto(
              fontWeight: FontWeight.w600,
              color: AppColors.text.withOpacity(0.9),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.roboto(color: AppColors.text),
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

    try {
      await userDoc.update({
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
        'registrationDate': FieldValue.serverTimestamp(),
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      // Ensure local user model is updated to reflect completion
      await authProvider.loadUserFromPrefs();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.t.auth('saveSuccess'))));

      // Navigate to main screen
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/main-screen', (route) => false);
    } catch (e) {
      if (!mounted) return;
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t.auth('saveError') + e.toString())),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showConfirmationDialog() {
    final yesNo = (bool value) =>
        value ? context.t.auth('yes') : context.t.auth('no');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // Consistent rounding
          ),
          title: Text(
            context.t.auth('confirmDetails'),
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildConfRow(context.t.auth('age'), ageController.text),
                _buildConfRow(
                  context.t.auth('residence'),
                  residenceController.text,
                ),
                const Divider(height: 20),
                _buildConfRow(context.t.auth('pregnancyMonth'), pregnancyMonth),
                _buildConfRow(
                  context.t.auth('firstTimeMother'),
                  yesNo(firstTimeMother),
                ),
                _buildConfRow(context.t.auth('employed'), yesNo(employed)),
                _buildConfRow(
                  context.t.auth('obstetricComplication'),
                  yesNo(obstetricComplication),
                ),
                _buildConfRow(
                  context.t.auth('psychologicalSupport'),
                  yesNo(psychologicalSupport),
                ),
                _buildConfRow(
                  context.t.auth('distressingEvents'),
                  yesNo(distressingEvents),
                ),
                _buildConfRow(
                  context.t.auth('practicedMindfulness'),
                  yesNo(practicedMindfulness),
                ),
                if (practicedMindfulness)
                  _buildConfRow(
                    context.t.auth('mindfulnessDuration'),
                    mindfulnessDuration,
                  ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.text,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      context.t.auth('cancel'),
                      style: GoogleFonts.roboto(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 5,
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _saveToFirebase();
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
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // --- Page Builder Functions ---

  Widget _buildPage1(BuildContext context, bool isMobile) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Page Title
        Text(
          context.t.auth('basicInfo'),
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: isMobile ? 32 : 36,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 30),

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
            if (numValue < 18 || numValue > 70)
              return context.t.auth('ageLimit');
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
            ElevatedButton(
              onPressed: _isSaving
                  ? null
                  : () {
                      HapticFeedback.lightImpact();
                      if (_formKey.currentState!.validate()) {
                        setState(() => _currentStep = 1);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.buttonText,
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 32,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 5,
              ),
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
              fontSize: isMobile ? 32 : 36,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 30),

          // Pregnancy Month Dropdown
          DropdownButtonFormField<String>(
            value: pregnancyMonth.isEmpty ? null : pregnancyMonth,
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
              if (!val) mindfulnessDuration = ''; // Reset duration if unchecked
            },
          ),
          const SizedBox(height: 10),

          // Mindfulness Duration Dropdown
          if (practicedMindfulness)
            Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: DropdownButtonFormField<String>(
                value: mindfulnessDuration.isEmpty ? null : mindfulnessDuration,
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
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 24,
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
              ElevatedButton(
                onPressed: _isSaving
                    ? null
                    : () {
                        HapticFeedback.mediumImpact();
                        if (_formKey.currentState!.validate()) {
                          setState(() {});
                          _showConfirmationDialog();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.buttonText,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 32,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                ),
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

    return WillPopScope(
      onWillPop: () async {
        if (_currentStep == 1) {
          HapticFeedback.lightImpact();
          setState(() => _currentStep = 0);
          return false;
        }

        DateTime now = DateTime.now();
        if (lastBackPressTime == null ||
            now.difference(lastBackPressTime!) > const Duration(seconds: 2)) {
          lastBackPressTime = now;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.t.auth('exitRegistrationMessage')),
              duration: const Duration(seconds: 2),
            ),
          );
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: Stack(
          children: [
            // Background image
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
            Container(
              width: double.infinity,
              height: double.infinity,
              color: AppColors.background.withOpacity(0.10),
            ),

            // Form Card
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 40,
                ),
                child: Container(
                  width: isMobile ? size.width * 0.9 : 500,
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 3,
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.05),
                        spreadRadius: -2,
                        blurRadius: 10,
                        offset: const Offset(-5, -5),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _currentStep == 0
                          ? _buildPage1(context, isMobile)
                          : _buildPage2(context, isMobile, isSinhala),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
