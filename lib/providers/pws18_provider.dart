import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import '../providers/achievement_provider.dart';
import '../services/pws18_service.dart';

class PWS18Provider with ChangeNotifier {
  final PWS18Service _pws18Service = PWS18Service();
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
  Map<String, List<int>> get subscales => {
    'Autonomy': [15, 17, 18],
    'Environmental Mastery': [4, 8, 9],
    'Personal Growth': [11, 12, 14],
    'Positive Relations with Others': [6, 13, 16],
    'Purpose in Life': [3, 7, 10],
    'Self-Acceptance': [1, 2, 5],
  };

  Map<String, double> calculateScores() {
    return _pws18Service.calculateScores(responses, subscales);
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
      final result = await _pws18Service.loadData(_user!.id);
      unlockDates = result.unlockDates;
      userAttempts = result.userAttempts;
      currentAttemptNumber = result.currentAttemptNumber;
      isLocked = result.isLocked;
      lockReason = result.lockReason;
    } catch (e) {
      print("Error loading PWS18 data: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Save Entire Attempt
  Future<void> saveAttemptToFirebase(BuildContext context) async {
    if (!allAnswered) return;
    if (_user == null) throw Exception("User not found");

    isLoading = true;
    notifyListeners();

    try {
      final subscaleScores = calculateScores();
      await _pws18Service.saveAttempt(
        userId: _user!.id,
        attemptNumber: currentAttemptNumber,
        responses: responses,
        subscaleScores: subscaleScores,
      );

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
