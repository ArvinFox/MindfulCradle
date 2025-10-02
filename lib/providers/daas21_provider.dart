import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class DAAS21Provider with ChangeNotifier {
  UserModel? _user;

  // Responses for 21 questions
  List<int?> responses = List<int?>.filled(21, null);

  DAAS21Provider();

  UserModel? get user => _user;

  void setUser(UserModel user) {
    _user = user;
    notifyListeners();
  }

  void setAnswer(int questionId, int value) {
    responses[questionId - 1] = value;
    notifyListeners();
  }

  bool get allAnswered => !responses.contains(null);

  // --- Calculate DASS-21 Scores ---
  Map<String, int> calculateScores() {
    final depressionQ = [3, 5, 10, 13, 16, 17, 21];
    final anxietyQ = [2, 4, 7, 9, 15, 19, 20];
    final stressQ = [1, 6, 8, 11, 12, 14, 18];

    int rawDe = depressionQ.fold(0, (sum, q) => sum + (responses[q - 1] ?? 0));
    int rawAn = anxietyQ.fold(0, (sum, q) => sum + (responses[q - 1] ?? 0));
    int rawSt = stressQ.fold(0, (sum, q) => sum + (responses[q - 1] ?? 0));

    return {
      'depression': rawDe * 2,
      'anxiety': rawAn * 2,
      'stress': rawSt * 2,
    };
  }

  // --- Severity Level Classification ---
  String classifyDepression(int score) {
    if (score <= 9) return 'Normal';
    if (score <= 13) return 'Mild';
    if (score <= 20) return 'Moderate';
    if (score <= 27) return 'Severe';
    return 'Extremely Severe';
  }

  String classifyAnxiety(int score) {
    if (score <= 7) return 'Normal';
    if (score <= 9) return 'Mild';
    if (score <= 14) return 'Moderate';
    if (score <= 19) return 'Severe';
    return 'Extremely Severe';
  }

  String classifyStress(int score) {
    if (score <= 14) return 'Normal';
    if (score <= 18) return 'Mild';
    if (score <= 25) return 'Moderate';
    if (score <= 33) return 'Severe';
    return 'Extremely Severe';
  }

  // --- Save to Firebase ---
  Future<void> saveToFirebase(BuildContext context) async {
    if (!allAnswered) return;

    final scores = calculateScores();
    final responseMap = Map.fromIterables(
      List.generate(21, (i) => (i + 1).toString()),
      responses.map((e) => e ?? 0),
    );

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = _user ?? authProvider.user;
    if (currentUser == null) throw Exception("User not found");

    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.id)
        .collection('dass21_responses')
        .doc('latest')
        .set({
      'responses': responseMap,
      'scores': scores,
      'completedAt': FieldValue.serverTimestamp(),
    });
  }

  void reset() {
    _user = null;
    responses = List<int?>.filled(21, null);
    notifyListeners();
  }
}
