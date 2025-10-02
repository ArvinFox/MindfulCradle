import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class PWS18Provider with ChangeNotifier {
  UserModel? _user;

  List<int?> responses = List<int?>.filled(18, null); // 18 questions

  PWS18Provider();

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

  /// Reverse scoring for specific items
  int _processedScore(int questionId, int value) {
    const reverseItems = [2,5,8,10,12,14];
    if (reverseItems.contains(questionId)) return 8 - value;
    return value;
  }

  /// Calculate subscale scores
  Map<String, double> calculateScores() {
    Map<String, List<int>> subscales = {
      'Autonomy': [5,6,17],
      'Environmental Mastery': [1,7,14],
      'Personal Growth': [3,12,18],
      'Positive Relations with Others': [2,9,15],
      'Purpose in Life': [8,11,13],
      'Self-Acceptance': [4,10,16],
    };

    Map<String, double> scores = {};
    subscales.forEach((key, items) {
      double total = 0;
      int count = 0;
      for (var qId in items) {
        final val = responses[qId - 1];
        if (val != null) {
          total += _processedScore(qId, val);
          count++;
        }
      }
      scores[key] = count > 0 ? total / count : 0;
    });

    return scores;
  }

  /// Save to Firestore
  Future<void> saveToFirebase(BuildContext context) async {
    if (!allAnswered) return;

    final subscaleScores = calculateScores();
    final responseMap = Map.fromIterables(
      List.generate(18, (i) => (i + 1).toString()),
      responses.map((e) => e ?? 0),
    );

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = _user ?? authProvider.user;
    if (currentUser == null) throw Exception("User not found");

    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.id)
        .collection('pws18_responses')
        .doc('latest')
        .set({
      'responses': responseMap,
      'subscaleScores': subscaleScores,
      'completedAt': FieldValue.serverTimestamp(),
    });
  }

  void reset() {
    _user = null;
    responses = List<int?>.filled(18, null);
    notifyListeners();
  }
}
