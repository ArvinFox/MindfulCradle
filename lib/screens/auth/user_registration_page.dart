import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/colors.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
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
        'mindfulnessDuration': practicedMindfulness
            ? mindfulnessDuration
            : null,
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

  Widget _buildPage1(BuildContext context, bool isMobile) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "Basic Information",
          style: TextStyle(
            fontSize: isMobile ? 24 : 28,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 20),

        // Age
        TextFormField(
          controller: ageController,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.inputBackground,
            labelText: "Age",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          keyboardType: TextInputType.number,
          validator: (val) {
            if (val == null || val.isEmpty) return "Required";
            final numValue = int.tryParse(val);
            if (numValue == null) return "Must be a number";
            if (numValue < 18 || numValue > 70) return "Age must be 18–70";
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Residence
        TextFormField(
          controller: residenceController,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.inputBackground,
            labelText: "Residence (City)",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (val) => val == null || val.isEmpty ? "Required" : null,
        ),
        const SizedBox(height: 16),

        // Identification Number
        TextFormField(
          controller: idController,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.inputBackground,
            labelText: "Identification Number (ID)",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (val) {
            if (val == null || val.isEmpty) return "Required";

            final oldIdReg = RegExp(r'^(\d{2})(\d{7})([VX])$');
            final newIdReg = RegExp(r'^(\d{4})(\d{8})$');
            final currentYear = DateTime.now().year;

            if (oldIdReg.hasMatch(val)) {
              final match = oldIdReg.firstMatch(val)!;
              final year = int.parse(match.group(1)!);
              if (year < 0 || year > 99) return "Invalid birth year in old ID";
            } else if (newIdReg.hasMatch(val)) {
              final match = newIdReg.firstMatch(val)!;
              final year = int.parse(match.group(1)!);
              if (year < 1900 || year > currentYear)
                return "Invalid birth year in new ID";
            } else {
              return "Invalid ID format";
            }
            return null;
          },
        ),

        const SizedBox(height: 24),

        // Next Button
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
                "Next",
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

  Widget _buildPage2(BuildContext context, bool isMobile) {
    final durationOptions = [
      "Less than 1 month",
      "2 months",
      "3 months",
      "4 months",
      "5 months",
      "6 months",
      "More than 6 months",
    ];

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Pregnancy & Background Info",
            style: TextStyle(
              fontSize: isMobile ? 24 : 28,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),

          // Pregnancy month dropdown
          DropdownButtonFormField<String>(
            value: pregnancyMonth.isEmpty ? null : pregnancyMonth,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.inputBackground,
              labelText: "Current month of pregnancy",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: List.generate(
              9,
              (index) => DropdownMenuItem(
                value: '${index + 1}',
                child: Text('${index + 1} month${index > 0 ? 's' : ''}'),
              ),
            ),
            onChanged: (val) => setState(() => pregnancyMonth = val ?? ''),
            validator: (val) => val == null || val.isEmpty ? "Required" : null,
          ),
          const SizedBox(height: 12),

          _buildCheckbox("First-time mother?", firstTimeMother, (val) {
            setState(() => firstTimeMother = val);
          }),
          _buildCheckbox("Employed?", employed, (val) {
            setState(() => employed = val);
          }),
          _buildCheckbox("Obstetric complication?", obstetricComplication, (
            val,
          ) {
            setState(() => obstetricComplication = val);
          }),
          _buildCheckbox(
            "Receiving psychological support?",
            psychologicalSupport,
            (val) {
              setState(() => psychologicalSupport = val);
            },
          ),
          _buildCheckbox(
            "Experiencing distressing life events?",
            distressingEvents,
            (val) {
              setState(() => distressingEvents = val);
            },
          ),
          _buildCheckbox(
            "Practiced mindfulness before?",
            practicedMindfulness,
            (val) {
              setState(() => practicedMindfulness = val);
            },
          ),

          if (practicedMindfulness)
            DropdownButtonFormField<String>(
              value: mindfulnessDuration.isEmpty ? null : mindfulnessDuration,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.inputBackground,
                labelText: "Mindfulness duration",
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
                  ? "Required"
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
                  "Back",
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
                          // Show confirmation dialog
                          showDialog(
                            context: context,
                            builder: (ctx) {
                              return AlertDialog(
                                title: const Text("Confirm your details"),
                                content: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text("Age: ${ageController.text}"),
                                      Text(
                                        "Residence: ${residenceController.text}",
                                      ),
                                      Text("ID Number: ${idController.text}"),
                                      Text("Pregnancy Month: $pregnancyMonth"),
                                      Text(
                                        "First-time mother: $firstTimeMother",
                                      ),
                                      Text("Employed: $employed"),
                                      Text(
                                        "Obstetric complication: $obstetricComplication",
                                      ),
                                      Text(
                                        "Psychological support: $psychologicalSupport",
                                      ),
                                      Text(
                                        "Distressing events: $distressingEvents",
                                      ),
                                      if (practicedMindfulness)
                                        Text(
                                          "Mindfulness duration: $mindfulnessDuration",
                                        ),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text("Edit"),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      _saveToFirebase();
                                    },
                                    child: const Text("Confirm"),
                                  ),
                                ],
                              );
                            },
                          );
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
                        "Finish",
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    DateTime? lastBackPressTime;

    return WillPopScope(
      onWillPop: () async {
        DateTime now = DateTime.now();
        if (lastBackPressTime == null ||
            now.difference(lastBackPressTime!) > const Duration(seconds: 2)) {
          lastBackPressTime = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Press back again to exit registration"),
              duration: Duration(seconds: 2),
            ),
          );
          return false; // prevent back
        }
        return true; // allow back on second press
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
                      ? _buildPage1(context, isMobile)
                      : _buildPage2(context, isMobile),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
