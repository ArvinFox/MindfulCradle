import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class PWS18LoadResult {
  final Map<int, DateTime> unlockDates;
  final Map<int, Map<String, dynamic>> userAttempts;
  final int currentAttemptNumber;
  final bool isLocked;
  final String lockReason;

  PWS18LoadResult({
    required this.unlockDates,
    required this.userAttempts,
    required this.currentAttemptNumber,
    required this.isLocked,
    required this.lockReason,
  });
}

class PWS18Service {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isCurrentUser(String userId) {
    final current = FirebaseAuth.instance.currentUser?.uid;
    return current != null && current == userId;
  }

  int _processedScore(int questionId, int value) {
    const reverseItems = [1, 2, 3, 8, 9, 11, 12, 13, 17, 18];
    if (reverseItems.contains(questionId)) {
      return 8 - value;
    }
    return value;
  }

  Map<String, double> calculateScores(
    List<int?> responses,
    Map<String, List<int>> subscales,
  ) {
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

  Future<PWS18LoadResult> loadData(String userId) async {
    final Map<int, DateTime> unlockDates = {};
    final Map<int, Map<String, dynamic>> userAttempts = {};

    final controlDoc = await _firestore
        .collection('questionnaire_control')
        .doc('pws18')
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
        .collection('pws18_responses')
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

    return PWS18LoadResult(
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
    required Map<String, double> subscaleScores,
  }) async {
    if (!_isCurrentUser(userId)) {
      if (kDebugMode) debugPrint('Blocked saveAttempt for non-owner.');
      return;
    }
    final responseMap = Map.fromIterables(
      List.generate(18, (i) => (i + 1).toString()),
      responses.map((e) => e ?? 0),
    );

    final docId = 'attempt_$attemptNumber';

    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('pws18_responses')
        .doc(docId);

    await docRef.set({
      'responses': responseMap,
      'subscaleScores': subscaleScores,
      'completedAt': FieldValue.serverTimestamp(),
      'attemptNumber': attemptNumber,
    });
  }

  _PWS18Status _determineCurrentStatus(
    Map<int, DateTime> unlockDates,
    Map<int, Map<String, dynamic>> userAttempts,
  ) {
    DateTime now = DateTime.now();

    if (!userAttempts.containsKey(1)) {
      DateTime? date = unlockDates[1];
      if (date != null && now.isAfter(date)) {
        return _PWS18Status(
          currentAttemptNumber: 1,
          isLocked: false,
          lockReason: '',
        );
      }
      return _PWS18Status(
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
        return _PWS18Status(
          currentAttemptNumber: 2,
          isLocked: false,
          lockReason: '',
        );
      }
      return _PWS18Status(
        currentAttemptNumber: 2,
        isLocked: true,
        lockReason: 'Locked',
      );
    }

    if (!userAttempts.containsKey(3)) {
      DateTime? date = unlockDates[3];
      if (date != null && now.isAfter(date)) {
        return _PWS18Status(
          currentAttemptNumber: 3,
          isLocked: false,
          lockReason: '',
        );
      }
      return _PWS18Status(
        currentAttemptNumber: 3,
        isLocked: true,
        lockReason: 'Locked',
      );
    }

    return _PWS18Status(
      currentAttemptNumber: 4,
      isLocked: true,
      lockReason: 'All attempts completed',
    );
  }
}

class _PWS18Status {
  final int currentAttemptNumber;
  final bool isLocked;
  final String lockReason;

  _PWS18Status({
    required this.currentAttemptNumber,
    required this.isLocked,
    required this.lockReason,
  });
}
