import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/achievement_provider.dart';
import '../services/dass21_service.dart';
import '../services/questionnaire_verdict_service.dart';
import 'package:provider/provider.dart';

class DASS21Provider with ChangeNotifier {
  final DASS21Service _dass21Service = DASS21Service();
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

  // Final verdict (available only after all 3 attempts)
  QuestionnaireVerdict? finalVerdict;

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
    return _dass21Service.calculateScores(responses);
  }

  // Classifications
  String classifyDepression(int score, {bool isSinhala = false}) {
    return _dass21Service.classifyDepression(score, isSinhala: isSinhala);
  }

  String classifyAnxiety(int score, {bool isSinhala = false}) {
    return _dass21Service.classifyAnxiety(score, isSinhala: isSinhala);
  }

  String classifyStress(int score, {bool isSinhala = false}) {
    return _dass21Service.classifyStress(score, isSinhala: isSinhala);
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
      final result = await _dass21Service.loadData(_user!.id);
      unlockDates = result.unlockDates;
      userAttempts = result.userAttempts;
      currentAttemptNumber = result.currentAttemptNumber;
      isLocked = result.isLocked;
      lockReason = result.lockReason;

      if (_user != null && userAttempts.length == 3) {
        finalVerdict = await VerdictFirestoreService.loadVerdict(
          userId: _user!.id,
          subcollection: 'dass21_responses',
        );
        if (finalVerdict == null) {
          finalVerdict = DASS21VerdictEngine.compute(userAttempts);
          await VerdictFirestoreService.saveVerdict(
            userId: _user!.id,
            subcollection: 'dass21_responses',
            verdict: finalVerdict!,
          );
        }
      } else {
        finalVerdict = null;
      }
    } catch (e) {
      if (kDebugMode) debugPrint("Error loading DASS data.");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Save Function
  Future<void> saveToFirebase(BuildContext context) async {
    if (!allAnswered) return;
    if (_user == null) throw Exception("User not found");

    isLoading = true;
    notifyListeners();

    try {
      final scores = calculateScores();
      await _dass21Service.saveAttempt(
        userId: _user!.id,
        attemptNumber: currentAttemptNumber,
        responses: responses,
        scores: scores,
      );

      // ACHIEVEMENT LOGIC: 'Self Aware'
      if (currentAttemptNumber == 1) {
        final achievementProvider = Provider.of<AchievementProvider>(
          context,
          listen: false,
        );
        await achievementProvider.unlockAchievement(
          context,
          'self_aware',
          showUI: false,
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
    finalVerdict = null;
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
