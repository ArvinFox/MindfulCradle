import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class MAASProvider with ChangeNotifier {
  UserModel? _user;

  // Global Unlock Dates
  Map<int, DateTime> unlockDates = {};

  // User's past history
  Map<int, Map<String, dynamic>> userAttempts = {};

  // Current active attempt
  int currentAttemptNumber = 1;
  bool isLocked = true;
  String lockReason = "";

  List<int?> responses = List<int?>.filled(15, null);
  bool isLoading = false;

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

  /// Logic
  double calculateScores() {
    final total = responses.fold<int>(0, (sum, val) => sum + (val ?? 0));
    return total / responses.length;
  }

  String classifyScore(double score, {bool isSinhala = false}) {
    if (score >= 4.0) {
      return isSinhala ? 'සතිමත් බව ඉහළයි' : 'High Level of Mindfulness';
    } else if (score >= 3.0) {
      return isSinhala
          ? 'සතිමත් බව සාමාන්‍යයි'
          : 'Average Level of Mindfulness';
    } else {
      return isSinhala ? 'සතිමත් බව අඩුයි' : 'Low Level of Mindfulness';
    }
  }

  /// Load Data (Control + History)
  Future<void> loadMAASData(BuildContext context) async {
    isLoading = true;
    responses = List<int?>.filled(15, null);
    notifyListeners();

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      _user = authProvider.user;
      if (_user == null) return;

      // Fetch Global Unlock Dates
      DocumentSnapshot controlDoc = await FirebaseFirestore.instance
          .collection('questionnaire_control')
          .doc('maas')
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
          .collection('maas_responses')
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
      print("Error loading MAAS data: $e");
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

  Future<void> saveToFirebase(BuildContext context) async {
    if (!allAnswered) return;
    if (_user == null) throw Exception("User not found");

    isLoading = true;
    notifyListeners();

    try {
      final maasScore = calculateScores();
      final responseMap = Map.fromIterables(
        List.generate(15, (i) => (i + 1).toString()),
        responses.map((e) => e ?? 0),
      );

      final docId = 'attempt_$currentAttemptNumber';

      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.id)
          .collection('maas_responses')
          .doc(docId);

      await docRef.set({
        'responses': responseMap,
        'maasScore': maasScore,
        'classification': classifyScore(maasScore),
        'completedAt': FieldValue.serverTimestamp(),
        'attemptNumber': currentAttemptNumber,
      });

      await loadMAASData(context);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    _user = null;
    responses = List<int?>.filled(15, null);
    userAttempts.clear();
    isLoading = false;
    notifyListeners();
  }

  // Helper to get past score data safely
  Map<String, dynamic>? getAttemptData(int attempt) {
    return userAttempts[attempt];
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

  Future<void> resetAndLoad(UserModel user, {BuildContext? context}) async {}
}
