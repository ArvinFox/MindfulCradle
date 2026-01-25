import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/achievement_provider.dart';
import 'package:provider/provider.dart';

class DASS21Provider with ChangeNotifier {
  UserModel? _user;

  // Global Unlock Dates
  Map<int, DateTime> unlockDates = {};

  // User's past history
  Map<int, Map<String, dynamic>> userAttempts = {};

  // Current active attempt (1, 2, or 3)
  int currentAttemptNumber = 1;
  bool isLocked = true;
  String lockReason = "";

  // Standard questionnaire state
  List<int?> responses = List<int?>.filled(21, null);
  bool isLoading = false;

  // Subscales
  final List<int> depressionQ = [3, 5, 10, 13, 16, 17, 21];
  final List<int> anxietyQ = [2, 4, 7, 9, 15, 19, 20];
  final List<int> stressQ = [1, 6, 8, 11, 12, 14, 18];

  DASS21Provider();

  UserModel? get user => _user;
  bool get allAnswered => !responses.contains(null);

  void setUser(UserModel user) {
    _user = user;
    notifyListeners();
  }

  void setAnswer(int questionId, int value) {
    responses[questionId - 1] = value;
    notifyListeners();
  }

  // Calculation Logic
  Map<String, int> calculateScores() {
    int rawDe = depressionQ.fold(0, (sum, q) => sum + (responses[q - 1] ?? 0));
    int rawAn = anxietyQ.fold(0, (sum, q) => sum + (responses[q - 1] ?? 0));
    int rawSt = stressQ.fold(0, (sum, q) => sum + (responses[q - 1] ?? 0));
    return {'depression': rawDe * 2, 'anxiety': rawAn * 2, 'stress': rawSt * 2};
  }

  // Classifications
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

  // Load Data
  Future<void> loadDASS21Data(BuildContext context) async {
    isLoading = true;
    responses = List<int?>.filled(21, null);
    notifyListeners();

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      _user = authProvider.user;
      if (_user == null) return;

      // Fetch Global Unlock Dates
      DocumentSnapshot controlDoc = await FirebaseFirestore.instance
          .collection('questionnaire_control')
          .doc('dass21')
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
          .collection('dass21_responses')
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
      print("Error loading DASS data: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _determineCurrentStatus() {
    DateTime now = DateTime.now();

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

    if (!userAttempts.containsKey(2)) {
      currentAttemptNumber = 2;
      DateTime? date = unlockDates[2];
      if (date != null && now.isAfter(date)) {
        isLocked = false;
      } else {
        isLocked = true;
        lockReason = "Locked";
      }
      return;
    }

    if (!userAttempts.containsKey(3)) {
      currentAttemptNumber = 3;
      DateTime? date = unlockDates[3];
      if (date != null && now.isAfter(date)) {
        isLocked = false;
      } else {
        isLocked = true;
        lockReason = "Locked";
      }
      return;
    }

    currentAttemptNumber = 4;
    isLocked = true;
    lockReason = "All attempts completed";
  }

  // Save Function
  Future<void> saveToFirebase(BuildContext context) async {
    if (!allAnswered) return;
    if (_user == null) throw Exception("User not found");

    isLoading = true;
    notifyListeners();

    try {
      final scores = calculateScores();
      final responseMap = Map.fromIterables(
        List.generate(21, (i) => (i + 1).toString()),
        responses.map((e) => e ?? 0),
      );

      final docId = 'attempt_$currentAttemptNumber';

      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.id)
          .collection('dass21_responses')
          .doc(docId);

      await docRef.set({
        'responses': responseMap,
        'scores': scores,
        'completedAt': FieldValue.serverTimestamp(),
        'attemptNumber': currentAttemptNumber,
      });

      // ACHIEVEMENT LOGIC: 'Self Aware'
      if (currentAttemptNumber == 1) {
        final achievementProvider = Provider.of<AchievementProvider>(
          context,
          listen: false,
        );
        await achievementProvider.unlockAchievement(
          context, 
          'self_aware', 
          showUI: false
        );
      }

      await loadDASS21Data(context);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    responses = List<int?>.filled(21, null);
    userAttempts.clear();
    isLoading = false;
    notifyListeners();
  }

  // Helper to get past score
  int? getPastScore(int attempt, String key) {
    if (userAttempts.containsKey(attempt)) {
      return userAttempts[attempt]!['scores'][key];
    }
    return null;
  }

  DateTime? getAttemptDate(int attempt) {
    if (userAttempts.containsKey(attempt)) {
      final dynamic timestamp = userAttempts[attempt]!['completedAt'];
      if (timestamp is Timestamp) {
        return timestamp.toDate();
      }
    }
    return null;
  }

  void resetAndLoad(UserModel user, {BuildContext? context}) {
    setUser(user);
    if (context != null) {
      loadDASS21Data(context);
    }
  }
}
