import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'localization_service.dart';

class DASS21LoadResult {
  final Map<int, DateTime> unlockDates;
  final Map<int, Map<String, dynamic>> userAttempts;
  final int currentAttemptNumber;
  final bool isLocked;
  final String lockReason;

  DASS21LoadResult({
    required this.unlockDates,
    required this.userAttempts,
    required this.currentAttemptNumber,
    required this.isLocked,
    required this.lockReason,
  });
}

class DASS21Service {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  final LocalizationService _loc = LocalizationService.instance;

  bool _isCurrentUser(String userId) {
    final current = FirebaseAuth.instance.currentUser?.uid;
    return current != null && current == userId;
  }

  final List<int> _depressionQ = [3, 5, 10, 13, 16, 17, 21];
  final List<int> _anxietyQ = [2, 4, 7, 9, 15, 19, 20];
  final List<int> _stressQ = [1, 6, 8, 11, 12, 14, 18];

  Map<String, int> calculateScores(List<int?> responses) {
    int rawDe = _depressionQ.fold(0, (sum, q) => sum + (responses[q - 1] ?? 0));
    int rawAn = _anxietyQ.fold(0, (sum, q) => sum + (responses[q - 1] ?? 0));
    int rawSt = _stressQ.fold(0, (sum, q) => sum + (responses[q - 1] ?? 0));
    return {'depression': rawDe * 2, 'anxiety': rawAn * 2, 'stress': rawSt * 2};
  }

  String classifyDepression(int score, {bool isSinhala = false}) {
    final lang = isSinhala ? 'si' : 'en';
    if (score <= 9) return _loc.questionnaires('normal', lang);
    if (score <= 13) return _loc.questionnaires('mild', lang);
    if (score <= 20) return _loc.questionnaires('moderate', lang);
    if (score <= 27) return _loc.questionnaires('severe', lang);
    return _loc.questionnaires('extremelySevere', lang);
  }

  String classifyAnxiety(int score, {bool isSinhala = false}) {
    final lang = isSinhala ? 'si' : 'en';
    if (score <= 7) return _loc.questionnaires('normal', lang);
    if (score <= 9) return _loc.questionnaires('mild', lang);
    if (score <= 14) return _loc.questionnaires('moderate', lang);
    if (score <= 19) return _loc.questionnaires('severe', lang);
    return _loc.questionnaires('extremelySevere', lang);
  }

  String classifyStress(int score, {bool isSinhala = false}) {
    final lang = isSinhala ? 'si' : 'en';
    if (score <= 14) return _loc.questionnaires('normal', lang);
    if (score <= 18) return _loc.questionnaires('mild', lang);
    if (score <= 25) return _loc.questionnaires('moderate', lang);
    if (score <= 33) return _loc.questionnaires('severe', lang);
    return _loc.questionnaires('extremelySevere', lang);
  }

  Future<DASS21LoadResult> loadData(String userId) async {
    final Map<int, DateTime> unlockDates = {};
    final Map<int, Map<String, dynamic>> userAttempts = {};

    final controlDoc = await _firestore
        .collection('questionnaire_control')
        .doc('dass21')
        .get();

    if (controlDoc.exists && controlDoc.data() != null) {
      final data = controlDoc.data() as Map<String, dynamic>;
      if (data['attempt_1_date'] != null) {
        unlockDates[1] = (data['attempt_1_date'] as Timestamp).toDate();
      }
      if (data['attempt_2_date'] != null) {
        unlockDates[2] = (data['attempt_2_date'] as Timestamp).toDate();
      }
      if (data['attempt_3_date'] != null) {
        unlockDates[3] = (data['attempt_3_date'] as Timestamp).toDate();
      }
    }

    final attemptSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('dass21_responses')
        .get();

    for (var doc in attemptSnapshot.docs) {
      if (doc.id.startsWith('attempt_')) {
        int? num = int.tryParse(doc.id.split('_').last);
        if (num != null) {
          userAttempts[num] = doc.data();
        }
      }
    }

    final status = _determineCurrentStatus(unlockDates, userAttempts);

    return DASS21LoadResult(
      unlockDates: unlockDates,
      userAttempts: userAttempts,
      currentAttemptNumber: status.currentAttemptNumber,
      isLocked: status.isLocked,
      lockReason: status.lockReason,
    );
  }

  Future<void> saveAttempt({
    required String userId,
    required int attemptNumber,
    required List<int?> responses,
    required Map<String, int> scores,
  }) async {
    if (!_isCurrentUser(userId)) {
      if (kDebugMode) debugPrint('Blocked saveAttempt for non-owner.');
      return;
    }
    final responseMap = Map.fromIterables(
      List.generate(21, (i) => (i + 1).toString()),
      responses.map((e) => e ?? 0),
    );

    final docId = 'attempt_$attemptNumber';

    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('dass21_responses')
        .doc(docId);

    await docRef.set({
      'responses': responseMap,
      'scores': scores,
      'completedAt': FieldValue.serverTimestamp(),
      'attemptNumber': attemptNumber,
    });
  }

  _DASS21Status _determineCurrentStatus(
    Map<int, DateTime> unlockDates,
    Map<int, Map<String, dynamic>> userAttempts,
  ) {
    DateTime now = DateTime.now();

    if (!userAttempts.containsKey(1)) {
      DateTime? date = unlockDates[1];
      if (date != null && now.isAfter(date)) {
        return _DASS21Status(
          currentAttemptNumber: 1,
          isLocked: false,
          lockReason: '',
        );
      }
      return _DASS21Status(
        currentAttemptNumber: 1,
        isLocked: true,
        lockReason: date != null
            ? 'Available on ${date.toString().split(' ')[0]}'
            : 'Locked',
      );
    }

    if (!userAttempts.containsKey(2)) {
      DateTime? date = unlockDates[2];
      if (date != null && now.isAfter(date)) {
        return _DASS21Status(
          currentAttemptNumber: 2,
          isLocked: false,
          lockReason: '',
        );
      }
      return _DASS21Status(
        currentAttemptNumber: 2,
        isLocked: true,
        lockReason: 'Locked',
      );
    }

    if (!userAttempts.containsKey(3)) {
      DateTime? date = unlockDates[3];
      if (date != null && now.isAfter(date)) {
        return _DASS21Status(
          currentAttemptNumber: 3,
          isLocked: false,
          lockReason: '',
        );
      }
      return _DASS21Status(
        currentAttemptNumber: 3,
        isLocked: true,
        lockReason: 'Locked',
      );
    }

    return _DASS21Status(
      currentAttemptNumber: 4,
      isLocked: true,
      lockReason: 'All attempts completed',
    );
  }
}

class _DASS21Status {
  final int currentAttemptNumber;
  final bool isLocked;
  final String lockReason;

  _DASS21Status({
    required this.currentAttemptNumber,
    required this.isLocked,
    required this.lockReason,
  });
}
