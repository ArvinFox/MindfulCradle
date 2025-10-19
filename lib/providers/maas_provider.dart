import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class MAASProvider with ChangeNotifier {
  UserModel? _user;

  List<int?> responses = List<int?>.filled(15, null); // 15 questions
  List<int> availableQuestionIds = [];
  bool isLoading = false;

  double? latestMAASScore;
  String? latestMAASClassification;
  DateTime? completedAt;

  MAASProvider();

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

  /// Calculate the MAAS score as the average of all responses
  double calculateScores() {
    final total = responses.fold<int>(0, (sum, val) => sum + (val ?? 0));
    return total / responses.length;
  }

  /// Classify the score according to your thresholds
  String classifyScore(double score, {bool isSinhala = false}) {
    if (score >= 4.0) {
      return isSinhala ? 'ඉහළ මනෝ අවධානය' : 'High Mindful Attention';
    } else if (score >= 3.0) {
      return isSinhala ? 'සාමාන්‍ය මනෝ අවධානය' : 'Average Mindful Attention';
    } else {
      return isSinhala ? 'අඩු මනෝ අවධානය' : 'Low Mindful Attention';
    }
  }

  /// --- Real-time Firestore updates stream ---
  Stream<Map<String, int?>> responsesStream() async* {
    final currentUser = _user;
    if (currentUser == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.id)
        .collection('maas_responses')
        .doc('latest');

    await for (var snapshot in docRef.snapshots()) {
      Map<String, int?> updatedResponses = {
        for (int i = 1; i <= 15; i++) i.toString(): null,
      };

      if (snapshot.exists && snapshot.data()?['responses'] != null) {
        final saved = Map<String, dynamic>.from(snapshot.data()!['responses']);
        for (var entry in saved.entries) {
          int qId = int.tryParse(entry.key) ?? 0;
          if (qId > 0 && qId <= 15) {
            updatedResponses[qId.toString()] = entry.value;
          }
        }
      }

      for (int i = 0; i < 15; i++) {
        responses[i] = updatedResponses[(i + 1).toString()];
      }

      notifyListeners();
      yield updatedResponses;
    }
  }

  /// --- Save to Firebase ---
  Future<void> saveToFirebase(BuildContext context) async {
    if (!allAnswered) return;

    final maasScore = calculateScores();

    final responseMap = Map.fromIterables(
      List.generate(15, (i) => (i + 1).toString()),
      responses.map((e) => e ?? 0),
    );

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = _user ?? authProvider.user;
    if (currentUser == null) throw Exception("User not found");

    _user = currentUser;

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.id)
        .collection('maas_responses')
        .doc('latest');

    await docRef.set({
      'responses': responseMap,
      'maasScore': maasScore,
      'classification': classifyScore(maasScore),
      'completedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    latestMAASScore = maasScore;
    latestMAASClassification = classifyScore(maasScore);
    notifyListeners();
  }

  /// --- Load latest responses ---
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
          .collection('maas_responses')
          .doc('latest')
          .get();

      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null && data['responses'] != null) {
          Map<String, dynamic> saved = Map<String, dynamic>.from(
            data['responses'],
          );
          completedAt = (data['completedAt'] as Timestamp).toDate();
          for (var entry in saved.entries) {
            int qId = int.tryParse(entry.key) ?? 0;
            if (qId > 0 && qId <= 15) responses[qId - 1] = entry.value;
          }

          latestMAASScore = (data['maasScore'] as num?)?.toDouble();
          latestMAASClassification = data['classification'] as String?;
          notifyListeners();
        }
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// --- Reset all data ---
  void reset() {
    _user = null;
    responses = List<int?>.filled(15, null);
    availableQuestionIds.clear();
    isLoading = false;
    latestMAASScore = null;
    latestMAASClassification = null;
    notifyListeners();
  }

  /// --- Reset and load a new user ---
  Future<void> resetAndLoad(UserModel user, {BuildContext? context}) async {
    reset();
    setUser(user);
    await loadLatest(context, user: user);
  }
}
