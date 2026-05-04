import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import '../providers/achievement_provider.dart';
import '../services/maas_service.dart';
import '../services/questionnaire_verdict_service.dart';

class MAASProvider with ChangeNotifier {
  final MAASService _maasService = MAASService();
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

  // Final verdict (available only after all 3 attempts)
  QuestionnaireVerdict? finalVerdict;

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
    return _maasService.calculateScores(responses);
  }

  String classifyScore(double score, {bool isSinhala = false}) {
    return _maasService.classifyScore(score, isSinhala: isSinhala);
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
      final result = await _maasService.loadData(_user!.id);
      unlockDates = result.unlockDates;
      userAttempts = result.userAttempts;
      currentAttemptNumber = result.currentAttemptNumber;
      isLocked = result.isLocked;
      lockReason = result.lockReason;

      if (_user != null && userAttempts.length == 3) {
        finalVerdict = await VerdictFirestoreService.loadVerdict(
          userId: _user!.id,
          subcollection: 'maas_responses',
        );
        if (finalVerdict == null) {
          finalVerdict = MAASVerdictEngine.compute(userAttempts);
          await VerdictFirestoreService.saveVerdict(
            userId: _user!.id,
            subcollection: 'maas_responses',
            verdict: finalVerdict!,
          );
        }
      } else {
        finalVerdict = null;
      }
    } catch (e) {
      if (kDebugMode) debugPrint("Error loading MAAS data.");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveToFirebase(BuildContext context) async {
    if (!allAnswered) return;
    if (_user == null) throw Exception("User not found");

    isLoading = true;
    notifyListeners();

    try {
      final maasScore = calculateScores();
      final classification = classifyScore(maasScore);
      await _maasService.saveAttempt(
        userId: _user!.id,
        attemptNumber: currentAttemptNumber,
        responses: responses,
        maasScore: maasScore,
        classification: classification,
      );

      // ACHIEVEMENT LOGIC: Unlock 'Mindful Observer'
      if (currentAttemptNumber == 1) {
        final achievementProvider = Provider.of<AchievementProvider>(
          context,
          listen: false,
        );
        await achievementProvider.unlockAchievement(
          context,
          'mindful_observer',
          showUI: false,
        );
      }

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
    finalVerdict = null;
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

  Future<void> resetAndLoad(UserModel user, {BuildContext? context}) async {
    setUser(user);
    if (context != null) {
      await loadMAASData(context);
    }
  }
}
