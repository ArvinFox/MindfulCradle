import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class MAASLoadResult {
  final Map<int, DateTime> unlockDates;
  final Map<int, Map<String, dynamic>> userAttempts;
  final int currentAttemptNumber;
  final bool isLocked;
  final String lockReason;

  MAASLoadResult({
    required this.unlockDates,
    required this.userAttempts,
    required this.currentAttemptNumber,
    required this.isLocked,
    required this.lockReason,
  });
}

class MAASService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isCurrentUser(String userId) {
    final current = FirebaseAuth.instance.currentUser?.uid;
    return current != null && current == userId;
  }

  double calculateScores(List<int?> responses) {
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

  Future<MAASLoadResult> loadData(String userId) async {
    final Map<int, DateTime> unlockDates = {};
    final Map<int, Map<String, dynamic>> userAttempts = {};

    final controlDoc = await _firestore
        .collection('questionnaire_control')
        .doc('maas')
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
        .collection('maas_responses')
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

    return MAASLoadResult(
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
    required double maasScore,
    required String classification,
  }) async {
    if (!_isCurrentUser(userId)) {
      if (kDebugMode) debugPrint('Blocked saveAttempt for non-owner.');
      return;
    }
    final responseMap = Map.fromIterables(
      List.generate(15, (i) => (i + 1).toString()),
      responses.map((e) => e ?? 0),
    );

    final docId = 'attempt_$attemptNumber';

    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('maas_responses')
        .doc(docId);

    await docRef.set({
      'responses': responseMap,
      'maasScore': maasScore,
      'classification': classification,
      'completedAt': FieldValue.serverTimestamp(),
      'attemptNumber': attemptNumber,
    });
  }

  _MAASStatus _determineCurrentStatus(
    Map<int, DateTime> unlockDates,
    Map<int, Map<String, dynamic>> userAttempts,
  ) {
    DateTime now = DateTime.now();

    if (!userAttempts.containsKey(1)) {
      DateTime? date = unlockDates[1];
      if (date != null && now.isAfter(date)) {
        return _MAASStatus(
          currentAttemptNumber: 1,
          isLocked: false,
          lockReason: '',
        );
      }
      return _MAASStatus(
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
        return _MAASStatus(
          currentAttemptNumber: 2,
          isLocked: false,
          lockReason: '',
        );
      }
      return _MAASStatus(
        currentAttemptNumber: 2,
        isLocked: true,
        lockReason: 'Locked',
      );
    }

    if (!userAttempts.containsKey(3)) {
      DateTime? date = unlockDates[3];
      if (date != null && now.isAfter(date)) {
        return _MAASStatus(
          currentAttemptNumber: 3,
          isLocked: false,
          lockReason: '',
        );
      }
      return _MAASStatus(
        currentAttemptNumber: 3,
        isLocked: true,
        lockReason: 'Locked',
      );
    }

    return _MAASStatus(
      currentAttemptNumber: 4,
      isLocked: true,
      lockReason: 'All attempts completed',
    );
  }
}

class _MAASStatus {
  final int currentAttemptNumber;
  final bool isLocked;
  final String lockReason;

  _MAASStatus({
    required this.currentAttemptNumber,
    required this.isLocked,
    required this.lockReason,
  });
}
