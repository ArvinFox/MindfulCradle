import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/colors.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  late TextEditingController idController;

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

  @override
  void initState() {
    super.initState();
    ageController = TextEditingController();
    residenceController = TextEditingController();
    idController = TextEditingController();
  }

  @override
  void dispose() {
    ageController.dispose();
    residenceController.dispose();
    idController.dispose();
    super.dispose();
  }

  Future<void> _saveToFirebase() async {
    setState(() => _isSaving = true);
    final userDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.user.id);

    // Map mindfulness durations to English values
    final mindfulnessMap = {
      texts['lessThan1Month']!: 'Less than 1 month',
      texts['1month']!: '1 Months',
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
        'age': ageController.text,
        'residence': residenceController.text,
        'identificationNumber': idController.text,
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
      authProvider.loadUserFromPrefs();

      if (!mounted) return;

      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/main-screen', (route) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error saving data: $e")));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Widget _buildCheckbox(
    String title,
    bool value,
    void Function(bool) onChanged,
  ) {
    return Row(
      children: [
        Checkbox(value: value, onChanged: (val) => onChanged(val ?? false)),
        Expanded(child: Text(title)),
      ],
    );
  }

  Widget _buildConfRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          Flexible(child: Text(value, textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  void _showConfirmationDialog(Map<String, String> texts) {
    final yesNo = (bool value) => value ? texts['yes']! : texts['no']!;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(texts['confirmDetails']!),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildConfRow(texts['age']!, ageController.text),
                _buildConfRow(texts['residence']!, residenceController.text),
                _buildConfRow(texts['idNumber']!, idController.text),
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
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[400],
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  texts['cancel']!,
                  style: const TextStyle(fontSize: 16),
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
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPage1(
    BuildContext context,
    bool isMobile,
    Map<String, String> texts,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          texts['basicInfo']!,
          style: TextStyle(
            fontSize: isMobile ? 24 : 28,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 20),

        TextFormField(
          controller: ageController,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.inputBackground,
            labelText: texts['age'],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          keyboardType: TextInputType.number,
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
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.inputBackground,
            labelText: texts['residence'],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (val) =>
              val == null || val.isEmpty ? texts['required'] : null,
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: idController,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.inputBackground,
            labelText: texts['idNumber'],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (val) {
            if (val == null || val.isEmpty) return texts['required'];

            final oldIdReg = RegExp(r'^(\d{2})(\d{7})([VX])$');
            final newIdReg = RegExp(r'^(\d{4})(\d{8})$');
            final currentYear = DateTime.now().year;

            if (oldIdReg.hasMatch(val)) {
              final match = oldIdReg.firstMatch(val)!;
              final year = int.parse(match.group(1)!);
              if (year < 0 || year > 99) return texts['invalidId'];
            } else if (newIdReg.hasMatch(val)) {
              final match = newIdReg.firstMatch(val)!;
              final year = int.parse(match.group(1)!);
              if (year < 1900 || year > currentYear) return texts['invalidId'];
            } else {
              return texts['invalidId'];
            }
            return null;
          },
        ),
        const SizedBox(height: 24),

        Row(
          children: [
            const Spacer(),
            ElevatedButton(
              onPressed: _isSaving
                  ? null
                  : () {
                      if (_formKey.currentState!.validate()) {
                        setState(() => _currentStep = 1);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 32,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                texts['next']!,
                style: TextStyle(
                  fontSize: isMobile ? 16 : 18,
                  color: AppColors.buttonText,
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
        children: [
          Text(
            texts['pregnancyInfo']!,
            style: TextStyle(
              fontSize: isMobile ? 24 : 28,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            value: pregnancyMonth.isEmpty ? null : pregnancyMonth,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.inputBackground,
              labelText: texts['pregnancyMonth'],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: List.generate(
              9,
              (index) => DropdownMenuItem(
                value: '${index + 1}',
                child: Text('${index + 1} ${texts['month']}'),
              ),
            ),
            onChanged: (val) => setState(() => pregnancyMonth = val ?? ''),
            validator: (val) =>
                val == null || val.isEmpty ? texts['required'] : null,
          ),
          const SizedBox(height: 12),

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
          }),

          if (practicedMindfulness)
            DropdownButtonFormField<String>(
              value: mindfulnessDuration.isEmpty ? null : mindfulnessDuration,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.inputBackground,
                labelText: texts['mindfulnessDuration'],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: durationOptions
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) =>
                  setState(() => mindfulnessDuration = val ?? ''),
              validator: (val) =>
                  practicedMindfulness && (val == null || val.isEmpty)
                  ? texts['required']
                  : null,
            ),
          const SizedBox(height: 24),

          Row(
            children: [
              ElevatedButton(
                onPressed: _isSaving
                    ? null
                    : () {
                        setState(() => _currentStep = 0);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.background,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 24,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.black26),
                  ),
                ),
                child: Text(
                  texts['back']!,
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 18,
                    color: AppColors.text,
                  ),
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _isSaving
                    ? null
                    : () {
                        if (_formKey.currentState!.validate()) {
                          _showConfirmationDialog(texts);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 32,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                        style: TextStyle(
                          fontSize: isMobile ? 16 : 18,
                          color: AppColors.buttonText,
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  late Map<String, String> texts;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final langProvider = Provider.of<LanguageProvider>(context);

    texts = langProvider.currentLang == 'en'
        ? {
            'basicInfo': 'Basic Information',
            'age': 'Age',
            'residence': 'Residence (City)',
            'idNumber': 'Identification Number (ID)',
            'required': 'Required',
            'mustNumber': 'Must be a number',
            'ageLimit': 'Age must be 18–70',
            'invalidId': 'Invalid ID format',
            'next': 'Next',
            'pregnancyInfo': 'Pregnancy & Background Info',
            'pregnancyMonth': 'Current month of pregnancy',
            'month': 'month',
            'firstTimeMother': 'First-time mother?',
            'employed': 'Employed?',
            'obstetricComplication': 'Obstetric complication?',
            'psychologicalSupport': 'Receiving psychological support?',
            'distressingEvents': 'Experiencing distressing life events?',
            'practicedMindfulness': 'Practiced mindfulness before?',
            'mindfulnessDuration': 'Mindfulness duration',
            'lessThan1Month': 'Less than 1 month',
            '1month': '1 Months',
            '2month': '2 Months',
            '3month': '3 Months',
            '4month': '4 Months',
            '5month': '5 Months',
            'moreThan6Months': 'More than 6 months',
            'back': 'Back',
            'confirmDetails': 'Confirm your details',
            'edit': 'Edit',
            'confirm': 'Confirm',
            'finish': 'Finish',
            'cancel': 'Cancel',
            'yes': 'Yes',
            'no': 'No',
          }
        : {
            'basicInfo': 'මූලික තොරතුරු',
            'age': 'වයස',
            'residence': 'නගරය / නේවාසික ස්ථානය',
            'idNumber': 'හැඳුනුම්පත් අංකය',
            'required': 'අවශ්‍යයි',
            'mustNumber': 'අංකයක් විය යුතුය',
            'ageLimit': 'වයස 18–70 අතර විය යුතුය',
            'invalidId': 'අවලංගු හැඳුනුම්පත් ආකෘතිය',
            'next': 'ඊළඟ',
            'pregnancyInfo': 'ගර්භණී සහ පසුබැසීමේ තොරතුරු',
            'pregnancyMonth': 'වත්මන් ගර්භ මාසය',
            'month': 'මාසය',
            'firstTimeMother': 'මුල් වරට මවක්ද?',
            'employed': 'රැකියාවක නිරත වේද?',
            'obstetricComplication': 'ගර්භාණු සම්බන්ධ අපහසුතා?',
            'psychologicalSupport': 'මානසික සහාය ලබනවාද?',
            'distressingEvents': 'පීඩාකාරී සිදුවීම් සිදුවේද/ සිදුවී තිබේද?',
            'practicedMindfulness': 'පෙර මනෝආවරණය පුරුදු වියදේද?',
            'mindfulnessDuration': 'මනෝආවරණ කාලය',
            'lessThan1Month': 'මාස 1ට අඩු',
            '1month': 'මාස 1 යි',
            '2month': 'මාස 2 යි',
            '3month': 'මාස 3 යි',
            '4month': 'මාස 4 යි',
            '5month': 'මාස 5 යි',
            'moreThan6Months': 'මාස 6ට වැඩි',
            'back': 'පසු',
            'confirmDetails': 'ඔබේ විස්තර තහවුරු කරන්න',
            'edit': 'සංස්කරණය කරන්න',
            'confirm': 'තහවුරු කරන්න',
            'finish': 'නිම කරන්න',
            'cancel': 'අවලංගු කරන්න',
            'yes': 'ඔව්',
            'no': 'නැත',
          };

    DateTime? lastBackPressTime;

    return WillPopScope(
      onWillPop: () async {
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
            Center(
              child: Container(
                width: isMobile ? size.width * 0.9 : 500,
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
                  child: _currentStep == 0
                      ? _buildPage1(context, isMobile, texts)
                      : _buildPage2(context, isMobile, texts),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
