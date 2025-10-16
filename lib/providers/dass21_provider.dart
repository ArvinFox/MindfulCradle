import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../providers/language_provider.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class DASS21Provider with ChangeNotifier {
  UserModel? _user;

  // Responses for 21 questions
  List<int?> responses = List<int?>.filled(21, null);
  List<int> availableQuestionIds = [];
  bool isLoading = false;

  DASS21Provider();

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

  // --- DAAS-21 Subscales ---
  final List<int> depressionQ = [3, 5, 10, 13, 16, 17, 21];
  final List<int> anxietyQ = [2, 4, 7, 9, 15, 19, 20];
  final List<int> stressQ = [1, 6, 8, 11, 12, 14, 18];

  Map<String, int> calculateScores() {
    int rawDe = depressionQ.fold(0, (sum, q) => sum + (responses[q - 1] ?? 0));
    int rawAn = anxietyQ.fold(0, (sum, q) => sum + (responses[q - 1] ?? 0));
    int rawSt = stressQ.fold(0, (sum, q) => sum + (responses[q - 1] ?? 0));

    return {'depression': rawDe * 2, 'anxiety': rawAn * 2, 'stress': rawSt * 2};
  }

  // --- Severity Classification ---
  String classifyDepression(int score, {bool isSinhala = false}) {
    if (score <= 9) return isSinhala ? 'සාමාන්‍ය' : 'Normal';
    if (score <= 13) return isSinhala ? 'මදක්' : 'Mild';
    if (score <= 20) return isSinhala ? 'මධ්‍යම' : 'Moderate';
    if (score <= 27) return isSinhala ? 'දරුණු' : 'Severe';
    return isSinhala ? 'අතිශය දරුණු' : 'Extremely Severe';
  }

  String classifyAnxiety(int score, {bool isSinhala = false}) {
    if (score <= 7) return isSinhala ? 'සාමාන්‍ය' : 'Normal';
    if (score <= 9) return isSinhala ? 'මදක්' : 'Mild';
    if (score <= 14) return isSinhala ? 'මධ්‍යම' : 'Moderate';
    if (score <= 19) return isSinhala ? 'දරුණු' : 'Severe';
    return isSinhala ? 'අතිශය දරුණු' : 'Extremely Severe';
  }

  String classifyStress(int score, {bool isSinhala = false}) {
    if (score <= 14) return isSinhala ? 'සාමාන්‍ය' : 'Normal';
    if (score <= 18) return isSinhala ? 'මදක්' : 'Mild';
    if (score <= 25) return isSinhala ? 'මධ්‍යම' : 'Moderate';
    if (score <= 33) return isSinhala ? 'දරුණු' : 'Severe';
    return isSinhala ? 'අතිශය දරුණු' : 'Extremely Severe';
  }

  /// Stream for real-time Firestore updates
  Stream<Map<String, int?>> responsesStream() async* {
    final currentUser = _user;
    if (currentUser == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.id)
        .collection('dass21_responses')
        .doc('latest');

    await for (var snapshot in docRef.snapshots()) {
      Map<String, int?> updatedResponses = {
        for (int i = 1; i <= 21; i++) i.toString(): null,
      };

      if (snapshot.exists && snapshot.data()?['responses'] != null) {
        final saved = Map<String, dynamic>.from(snapshot.data()!['responses']);
        for (var entry in saved.entries) {
          int qId = int.tryParse(entry.key) ?? 0;
          if (qId > 0 && qId <= 21) {
            updatedResponses[qId.toString()] = entry.value;
          }
        }
      }

      for (int i = 0; i < 21; i++) {
        responses[i] = updatedResponses[(i + 1).toString()];
      }
      notifyListeners();
      yield updatedResponses;
    }
  }

  /// Save all answers to Firebase
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

    _user = currentUser;

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.id)
        .collection('dass21_responses')
        .doc('latest');

    await docRef.set({
      'responses': responseMap,
      'scores': scores,
      'completedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Load latest responses
  Future<void> loadLatest(BuildContext? context, {UserModel? user}) async {
    reset();
    final authProvider = context != null
        ? Provider.of<AuthProvider>(context, listen: false)
        : null;

    final currentUser = user ?? _user ?? authProvider?.user;
    if (currentUser == null) return;

    _user = currentUser;

    try {
      isLoading = true;
      notifyListeners();

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.id)
          .collection('dass21_responses')
          .doc('latest')
          .get();

      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null && data['responses'] != null) {
          Map<String, dynamic> saved = Map<String, dynamic>.from(
            data['responses'],
          );
          for (var entry in saved.entries) {
            int qId = int.tryParse(entry.key) ?? 0;
            if (qId > 0 && qId <= 21) responses[qId - 1] = entry.value;
          }
          notifyListeners();
        }
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Reset all
  void reset() {
    _user = null;
    responses = List<int?>.filled(21, null);
    availableQuestionIds.clear();
    isLoading = false;
    notifyListeners();
  }

  /// Reset and load a new user
  Future<void> resetAndLoad(UserModel user, {BuildContext? context}) async {
    reset();
    setUser(user);
    await loadLatest(context, user: user);
  }
}
