import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class PWS18Provider with ChangeNotifier {
  UserModel? _user;

  // Full 18 questions (null = unanswered)
  List<int?> responses = List<int?>.filled(18, null);

  // Available question IDs loaded from Firestore
  List<int> availableQuestionIds = [];

  // loading flag
  bool isLoading = false;

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

  /// Reverse scoring for specific items
  int _processedScore(int questionId, int value) {
    const reverseItems = [2, 5, 8, 10, 12, 14];
    if (reverseItems.contains(questionId)) return 7 - value;
    return value;
  }

  /// Subscale definitions
  Map<String, List<int>> get subscales => {
        'Autonomy': [5, 6, 17],
        'Environmental Mastery': [1, 7, 14],
        'Personal Growth': [3, 12, 18],
        'Positive Relations with Others': [2, 9, 15],
        'Purpose in Life': [8, 11, 13],
        'Self-Acceptance': [4, 10, 16],
      };

  /// Calculate subscale scores (averages)
  Map<String, double> calculateScores() {
    final Map<String, double> scores = {};
    subscales.forEach((subscale, items) {
      double total = 0;
      int count = 0;
      for (var qId in items) {
        final val = responses[qId - 1];
        if (val != null) {
          total += _processedScore(qId, val).toDouble();
          count++;
        }
      }
      scores[subscale] = count > 0 ? total / count : 0.0;
    });
    return scores;
  }

  bool categoryAnswered(String categoryName) {
    final items = subscales[categoryName];
    if (items == null) return false;
    for (var qId in items) {
      if (responses[qId - 1] == null) return false;
    }
    return true;
  }

  bool allCategoriesAnswered() {
    for (var cat in subscales.keys) {
      if (!categoryAnswered(cat)) return false;
    }
    return true;
  }

  /// Check if category is completed
  bool isCategoryCompleted(String categoryName) {
    return categoryAnswered(categoryName);
  }

  /// Stream for real-time responses updates
  Stream<Map<String, int?>> get responsesStream async* {
    final currentUser = _user;
    if (currentUser == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.id)
        .collection('pws18_responses')
        .doc('latest');

    await for (var snapshot in docRef.snapshots()) {
      Map<String, int?> updatedResponses = Map.fromIterable(
        List.generate(18, (index) => index + 1),
        key: (i) => i.toString(),
        value: (i) => null,
      );

      if (snapshot.exists && snapshot.data()?['responses'] != null) {
        final saved = Map<String, dynamic>.from(snapshot.data()!['responses']);
        for (var entry in saved.entries) {
          int qId = int.tryParse(entry.key) ?? 0;
          if (qId > 0 && qId <= 18) {
            updatedResponses[qId.toString()] = entry.value;
          }
        }
      }

      // Update local state
      for (int i = 0; i < 18; i++) {
        responses[i] = updatedResponses[(i + 1).toString()];
      }
      notifyListeners();

      yield updatedResponses;
    }
  }

  /// Save only current category answers
  Future<void> saveCategoryAnswers(String category, {BuildContext? context}) async {
    final currentUser = _user ??
        (context != null
            ? Provider.of<AuthProvider>(context, listen: false).user
            : null);

    if (currentUser == null) throw Exception("User not logged in");

    _user = currentUser;

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.id)
        .collection('pws18_responses')
        .doc('latest');

    // Load existing responses
    final snap = await docRef.get();
    Map<String, dynamic> existingResponses = {};
    if (snap.exists && snap.data()?['responses'] != null) {
      existingResponses = Map<String, dynamic>.from(snap.data()!['responses']);
    }

    // Merge only current category responses
    final ids = subscales[category]!;
    for (var id in ids) {
      existingResponses[id.toString()] = responses[id - 1];
    }

    // Save merged responses
    await docRef.set({
      'responses': existingResponses,
      'completedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // If all 18 questions answered → calculate subscales
    if (!existingResponses.values.contains(null)) {
      await docRef.set({
        'subscaleScores': calculateScores(),
        'finalCompletedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  /// Load latest saved answers
  Future<void> loadLatest(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = _user ?? authProvider.user;
    if (currentUser == null) return;

    _user = currentUser;

    try {
      isLoading = true; // Start loading
      notifyListeners();

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.id)
          .collection('pws18_responses')
          .doc('latest')
          .get();

      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null && data['responses'] != null) {
          Map<String, dynamic> saved =
              Map<String, dynamic>.from(data['responses']);
          for (var entry in saved.entries) {
            int qId = int.tryParse(entry.key) ?? 0;
            if (qId > 0 && qId <= 18) {
              responses[qId - 1] = entry.value;
            }
          }
          notifyListeners();
        }
      }
    } finally {
      isLoading = false; // Stop loading
      notifyListeners();
    }
  }

  /// Load available question IDs from Firestore
  Future<void> loadAvailableQuestions(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = _user ?? authProvider.user;
    if (currentUser == null) return;

    availableQuestionIds.clear();

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.id)
        .collection('pws18_responses')
        .doc('latest')
        .get();

    if (snapshot.exists) {
      final data = snapshot.data();
      if (data != null && data['responses'] != null) {
        Map<String, dynamic> saved =
            Map<String, dynamic>.from(data['responses']);
        for (var entry in saved.entries) {
          int qId = int.tryParse(entry.key) ?? 0;
          if (qId > 0 && qId <= 18) {
            availableQuestionIds.add(qId);
          }
        }
      }
    }

    notifyListeners();
  }

  void reset() {
    _user = null;
    responses = List<int?>.filled(18, null);
    availableQuestionIds.clear();
    isLoading = false; // reset loading
    notifyListeners();
  }
}
