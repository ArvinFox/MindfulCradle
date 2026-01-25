import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import '../providers/achievement_provider.dart';

class PWS18Provider with ChangeNotifier {
  UserModel? _user;

  // Global Unlock Dates
  Map<int, DateTime> unlockDates = {};

  // User's past history
  Map<int, Map<String, dynamic>> userAttempts = {};

  // Current active attempt
  int currentAttemptNumber = 1;
  bool isLocked = true;
  String lockReason = "";

  // Standard questionnaire state
  List<int?> responses = List<int?>.filled(18, null);
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

  bool get allAnswered => !responses.contains(null);

  /// Logic
  int _processedScore(int questionId, int value) {
    const reverseItems = [1, 2, 3, 8, 9, 11, 12, 13, 17, 18];
    if (reverseItems.contains(questionId)) {
      return 8 - value;
    }
    return value;
  }

  Map<String, List<int>> get subscales => {
    'Autonomy': [15, 17, 18],
    'Environmental Mastery': [4, 8, 9],
    'Personal Growth': [11, 12, 14],
    'Positive Relations with Others': [6, 13, 16],
    'Purpose in Life': [3, 7, 10],
    'Self-Acceptance': [1, 2, 5],
  };

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

  /// Load Data (Control + History)
  Future<void> loadPWS18Data(BuildContext context) async {
    isLoading = true;
    responses = List<int?>.filled(18, null);
    notifyListeners();

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      _user = authProvider.user;
      if (_user == null) return;

      // Fetch Global Unlock Dates
      DocumentSnapshot controlDoc = await FirebaseFirestore.instance
          .collection('questionnaire_control')
          .doc('pws18')
          .get();

      if (controlDoc.exists && controlDoc.data() != null) {
        final data = controlDoc.data() as Map<String, dynamic>;
        if (data['attempt_1_date'] != null)
          unlockDates[1] = (data['attempt_1_date'] as Timestamp).toDate();
        if (data['attempt_2_date'] != null)
          unlockDates[2] = (data['attempt_2_date'] as Timestamp).toDate();
        if (data['attempt_3_date'] != null)
          unlockDates[3] = (data['attempt_3_date'] as Timestamp).toDate();
      }

      // Fetch User's Past Attempts
      QuerySnapshot attemptSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.id)
          .collection('pws18_responses')
          .get();

      userAttempts.clear();
      for (var doc in attemptSnapshot.docs) {
        if (doc.id.startsWith('attempt_')) {
          int? num = int.tryParse(doc.id.split('_').last);
          if (num != null) {
            userAttempts[num] = doc.data() as Map<String, dynamic>;
          }
        }
      }

      _determineCurrentStatus();
    } catch (e) {
      print("Error loading PWS18 data: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _determineCurrentStatus() {
    DateTime now = DateTime.now();

    // Check Attempt 1
    if (!userAttempts.containsKey(1)) {
      currentAttemptNumber = 1;
      DateTime? date = unlockDates[1];
      if (date != null && now.isAfter(date)) {
        isLocked = false;
      } else {
        isLocked = true;
        lockReason = "Available on ${date.toString().split(' ')[0]}";
      }
      return;
    }

    // Check Attempt 2
    if (!userAttempts.containsKey(2)) {
      currentAttemptNumber = 2;
      DateTime? date = unlockDates[2];
      if (date != null && now.isAfter(date)) {
        isLocked = false;
      } else {
        isLocked = true;
      }
      return;
    }

    // Check Attempt 3
    if (!userAttempts.containsKey(3)) {
      currentAttemptNumber = 3;
      DateTime? date = unlockDates[3];
      if (date != null && now.isAfter(date)) {
        isLocked = false;
      } else {
        isLocked = true;
      }
      return;
    }

    currentAttemptNumber = 4;
    isLocked = true;
  }

  /// Save Entire Attempt
  Future<void> saveAttemptToFirebase(BuildContext context) async {
    if (!allAnswered) return;
    if (_user == null) throw Exception("User not found");

    isLoading = true;
    notifyListeners();

    try {
      final subscaleScores = calculateScores();

      // Create map of all responses
      final responseMap = Map.fromIterables(
        List.generate(18, (i) => (i + 1).toString()),
        responses.map((e) => e ?? 0),
      );

      final docId = 'attempt_$currentAttemptNumber';

      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.id)
          .collection('pws18_responses')
          .doc(docId);

      await docRef.set({
        'responses': responseMap,
        'subscaleScores': subscaleScores,
        'completedAt': FieldValue.serverTimestamp(),
        'attemptNumber': currentAttemptNumber,
      });

      // ACHIEVEMENT LOGIC: Unlock 'Happiness Seeker'
      if (currentAttemptNumber == 1) {
        final achievementProvider = Provider.of<AchievementProvider>(
          context,
          listen: false,
        );
        await achievementProvider.unlockAchievement(
          context,
          'happiness_seeker',
          showUI: false,
        );
      }

      await loadPWS18Data(context);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Helper to get past scores safely
  Map<String, double>? getPastScores(int attempt) {
    if (userAttempts.containsKey(attempt)) {
      final data = userAttempts[attempt]!['subscaleScores'];
      if (data != null) {
        return Map<String, double>.from(
          data.map((k, v) => MapEntry(k, (v as num).toDouble())),
        );
      }
    }
    return null;
  }

  // Helper to get date safely
  DateTime? getAttemptDate(int attempt) {
    if (userAttempts.containsKey(attempt)) {
      final dynamic timestamp = userAttempts[attempt]!['completedAt'];
      if (timestamp is Timestamp) {
        return timestamp.toDate();
      }
    }
    return null;
  }

  void reset() {
    _user = null;
    responses = List<int?>.filled(18, null);
    userAttempts.clear();
    isLoading = false;
    notifyListeners();
  }

  Future<void> resetAndLoad(UserModel user, {BuildContext? context}) async {
    setUser(user);
    if (context != null) {
      await loadPWS18Data(context);
    }
  }
}
