import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class PWS18Provider with ChangeNotifier {
  UserModel? _user;

  List<int?> responses = List<int?>.filled(18, null);
  List<int> availableQuestionIds = [];
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

  /// Official reverse scoring items
  int _processedScore(int questionId, int value) {
    const reverseItems = [1, 2, 3, 8, 9, 11, 12, 13, 17, 18];
    if (reverseItems.contains(questionId)) {
      // Formula: (7 + 1) - value = 8 - value
      return 8 - value;
    }
    return value;
  }

  /// Official subscale mapping
  Map<String, List<int>> get subscales => {
        'Autonomy': [15, 17, 18],
        'Environmental Mastery': [4, 8, 9],
        'Personal Growth': [11, 12, 14],
        'Positive Relations with Others': [6, 13, 16],
        'Purpose in Life': [3, 7, 10],
        'Self-Acceptance': [1, 2, 5],
      };

  /// Calculate subscale scores (average per category)
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
    return subscales.keys.every((cat) => categoryAnswered(cat));
  }

  /// Real-time stream for user responses
  Stream<Map<String, int?>> responsesStream() async* {
    final currentUser = _user;
    if (currentUser == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.id)
        .collection('pws18_responses')
        .doc('latest');

    await for (var snapshot in docRef.snapshots()) {
      Map<String, int?> updatedResponses = {
        for (int i = 1; i <= 18; i++) i.toString(): null,
      };

      if (snapshot.exists && snapshot.data()?['responses'] != null) {
        final saved = Map<String, dynamic>.from(snapshot.data()!['responses']);
        for (var entry in saved.entries) {
          int qId = int.tryParse(entry.key) ?? 0;
          if (qId > 0 && qId <= 18) {
            updatedResponses[qId.toString()] = entry.value;
          }
        }
      }

      for (int i = 0; i < 18; i++) {
        responses[i] = updatedResponses[(i + 1).toString()];
      }
      notifyListeners();
      yield updatedResponses;
    }
  }

  /// Save answers of a single category
  Future<void> saveCategoryAnswers(String category,
      {BuildContext? context}) async {
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

    final snap = await docRef.get();
    Map<String, dynamic> existingResponses = {};
    if (snap.exists && snap.data()?['responses'] != null) {
      existingResponses = Map<String, dynamic>.from(snap.data()!['responses']);
    }

    final ids = subscales[category]!;
    for (var id in ids) {
      existingResponses[id.toString()] = responses[id - 1];
    }

    await docRef.set({
      'responses': existingResponses,
      'completedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (!existingResponses.values.contains(null)) {
      await docRef.set({
        'subscaleScores': calculateScores(),
        'finalCompletedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
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
          .collection('pws18_responses')
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
            if (qId > 0 && qId <= 18) responses[qId - 1] = entry.value;
          }
          notifyListeners();
        }
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Reset everything
  void reset() {
    _user = null;
    responses = List<int?>.filled(18, null);
    availableQuestionIds.clear();
    isLoading = false;
    notifyListeners();
  }

  /// Reset and load new user
  Future<void> resetAndLoad(UserModel user, {BuildContext? context}) async {
    reset();
    setUser(user);
    await loadLatest(context, user: user);
  }
}
