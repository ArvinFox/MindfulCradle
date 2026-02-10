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

    // Map mindfulness durations to English values
    final mindfulnessMap = {
      texts['lessThan1Month']!: 'Less than 1 month',
      texts['1month']!: '1 Month',
      texts['2month']!: '2 Months',
      texts['3month']!: '3 Months',
      texts['4month']!: '4 Months',
      texts['5month']!: '5 Months',
      texts['moreThan6Months']!: 'More than 6 months',
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(texts['saveSuccess'] ?? 'Registration complete!'),
        ),
      );

      // Navigate to main screen
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/main-screen', (route) => false);
    } catch (e) {
      if (!mounted) return;
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(texts['saveError']! + e.toString())),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showConfirmationDialog(Map<String, String> texts) {
    final yesNo = (bool value) => value ? texts['yes']! : texts['no']!;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // Consistent rounding
          ),
          title: Text(
            texts['confirmDetails']!,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildConfRow(texts['age']!, ageController.text),
                _buildConfRow(texts['residence']!, residenceController.text),
                const Divider(height: 20),
                _buildConfRow(texts['pregnancyMonth']!, pregnancyMonth),
                _buildConfRow(
                  texts['firstTimeMother']!,
                  yesNo(firstTimeMother),
                ),
                _buildConfRow(texts['employed']!, yesNo(employed)),
                _buildConfRow(
                  texts['obstetricComplication']!,
                  yesNo(obstetricComplication),
                ),
                _buildConfRow(
                  texts['psychologicalSupport']!,
                  yesNo(psychologicalSupport),
                ),
                _buildConfRow(
                  texts['distressingEvents']!,
                  yesNo(distressingEvents),
                ),
                _buildConfRow(
                  texts['practicedMindfulness']!,
                  yesNo(practicedMindfulness),
                ),
                if (practicedMindfulness)
                  _buildConfRow(
                    texts['mindfulnessDuration']!,
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
                      texts['cancel']!,
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
                            texts['confirm']!,
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

  Widget _buildPage1(
    BuildContext context,
    bool isMobile,
    Map<String, String> texts,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Page Title
        Text(
          texts['basicInfo']!,
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
          decoration: customInputDecoration(texts['age']!),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(2),
          ],
          validator: (val) {
            if (val == null || val.isEmpty) return texts['required'];
            final numValue = int.tryParse(val);
            if (numValue == null) return texts['mustNumber'];
            if (numValue < 18 || numValue > 70) return texts['ageLimit'];
            return null;
          },
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: residenceController,
          decoration: customInputDecoration(texts['residence']!),
          inputFormatters: [
            FilteringTextInputFormatter.deny(RegExp(r'[\r\n\t]')),
            LengthLimitingTextInputFormatter(80),
          ],
          validator: (val) =>
              val == null || val.isEmpty ? texts['required'] : null,
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
                texts['next']!,
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

  Widget _buildPage2(
    BuildContext context,
    bool isMobile,
    Map<String, String> texts,
    bool isSinhala,
  ) {
    final durationOptions = [
      texts['lessThan1Month']!,
      texts['1month']!,
      texts['2month']!,
      texts['3month']!,
      texts['4month']!,
      texts['5month']!,
      texts['moreThan6Months']!,
    ];

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Page Title
          Text(
            texts['pregnancyInfo']!,
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
            decoration: customInputDecoration(texts['pregnancyMonth']!),
            items: List.generate(9, (index) {
              final monthValue = index + 1;
              final monthLabel = isSinhala
                  ? texts['month']!
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
                val == null || val.isEmpty ? texts['required'] : null,
          ),
          const SizedBox(height: 20),

          // Checkboxes
          _buildCheckbox(texts['firstTimeMother']!, firstTimeMother, (val) {
            setState(() => firstTimeMother = val);
          }),
          _buildCheckbox(texts['employed']!, employed, (val) {
            setState(() => employed = val);
          }),
          _buildCheckbox(
            texts['obstetricComplication']!,
            obstetricComplication,
            (val) {
              setState(() => obstetricComplication = val);
            },
          ),
          _buildCheckbox(texts['psychologicalSupport']!, psychologicalSupport, (
            val,
          ) {
            setState(() => psychologicalSupport = val);
          }),
          _buildCheckbox(texts['distressingEvents']!, distressingEvents, (val) {
            setState(() => distressingEvents = val);
          }),
          _buildCheckbox(texts['practicedMindfulness']!, practicedMindfulness, (
            val,
          ) {
            setState(() => practicedMindfulness = val);
            if (!val) mindfulnessDuration = ''; // Reset duration if unchecked
          }),
          const SizedBox(height: 10),

          // Mindfulness Duration Dropdown
          if (practicedMindfulness)
            Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: DropdownButtonFormField<String>(
                value: mindfulnessDuration.isEmpty ? null : mindfulnessDuration,
                decoration: customInputDecoration(
                  texts['mindfulnessDuration']!,
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
                    ? texts['required']
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
                  texts['back']!,
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
                          _showConfirmationDialog(texts);
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
                        texts['finish']!,
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

  late Map<String, String> texts;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final langProvider = Provider.of<LanguageProvider>(context);
    final isSinhala = langProvider.currentLang == 'si';

    texts = langProvider.currentLang == 'en'
        ? {
            'basicInfo': 'Basic Information',
            'age': 'Age',
            'residence': 'Residence (City)',
            'required': 'Required',
            'mustNumber': 'Must be a number',
            'ageLimit': 'Age must be 18–70',
            'next': 'Next',
            'pregnancyInfo': 'Background Info',
            'pregnancyMonth': 'Current month of pregnancy',
            'month': 'month',
            'firstTimeMother': 'Are you a First-time mother?',
            'employed': 'Are you employed?',
            'obstetricComplication': 'Have any pregnancy complications?',
            'psychologicalSupport': 'Undergoing psychological therapy',
            'distressingEvents': 'Experiencing distressing life events',
            'practicedMindfulness': 'Have you practiced mindfulness before?',
            'mindfulnessDuration': 'Mindfulness practice duration',
            'lessThan1Month': 'Less than 1 month',
            '1month': '1 Month',
            '2month': '2 Months',
            '3month': '3 Months',
            '4month': '4 Months',
            '5month': '5 Months',
            'moreThan6Months': 'More than 6 months',
            'back': 'Back',
            'confirmDetails': 'Confirm Your Details',
            'confirm': 'Confirm',
            'finish': 'Finish',
            'cancel': 'Cancel',
            'yes': 'Yes',
            'no': 'No',
            'saveSuccess': 'Registration complete!',
            'saveError': 'Error saving data: ',
          }
        : {
            'basicInfo': 'මූලික තොරතුරු',
            'age': 'වයස',
            'residence': 'නගරය / නේවාසික ස්ථානය',
            'required': 'අවශ්‍යයි',
            'mustNumber': 'අංකයක් විය යුතුය',
            'ageLimit': 'වයස 18–70 අතර විය යුතුය',
            'next': 'ඊළඟ',
            'pregnancyInfo': 'පසුබිම් තොරතුරු',
            'pregnancyMonth': 'වත්මන් ගර්භණී මාසය',
            'month': 'මාසය',
            'firstTimeMother': 'මෙය පළමු ගැබ් ගැනීමද?',
            'employed': 'රැකියාවක නිරත වේද?',
            'obstetricComplication': 'ගර්භණී සංකුලතා තිබේද?',
            'psychologicalSupport': 'මානසික ප්‍රතිකාර ලබනවාද?',
            'distressingEvents': 'මානසික පීඩාකාරී සිදුවීම් අත්විඳිනවාද?',
            'practicedMindfulness': 'සතිමත්බව පුහුණුකර තිබේද?',
            'mindfulnessDuration': 'එසේ නම් කොපමණ කල්ද?',
            'lessThan1Month': 'මාස 1ට අඩු',
            '1month': 'මාස 1 යි',
            '2month': 'මාස 2 යි',
            '3month': 'මාස 3 යි',
            '4month': 'මාස 4 යි',
            '5month': 'මාස 5 යි',
            'moreThan6Months': 'මාස 6ට වැඩි',
            'back': 'පසු',
            'confirmDetails': 'ඔබේ විස්තර තහවුරු කරන්න',
            'confirm': 'තහවුරු කරන්න',
            'finish': 'නිම කරන්න',
            'cancel': 'අවලංගු කරන්න',
            'yes': 'ඔව්',
            'no': 'නැත',
            'saveSuccess': 'ලියාපදිංචිය සම්පූර්ණයි!',
            'saveError': 'දත්ත ගබඩා කිරීමේ දෝෂය: ',
          };

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
              content: Text(
                langProvider.currentLang == 'en'
                    ? "Press back again to exit registration"
                    : "ලියාපදිංචිය පිටවීමට නැවත පිටුතීරන්න",
              ),
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
                          ? _buildPage1(context, isMobile, texts)
                          : _buildPage2(context, isMobile, texts, isSinhala),
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
