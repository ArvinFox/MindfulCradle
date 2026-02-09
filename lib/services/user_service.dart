import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isCurrentUser(String userId) {
    final current = FirebaseAuth.instance.currentUser?.uid;
    return current != null && current == userId;
  }

  /// Increment total session time for a user
  Future<void> updateTotalSessionTime({
    required String userId,
    required int additionalSeconds,
  }) async {
    if (!_isCurrentUser(userId)) {
      if (kDebugMode) {
        debugPrint('Blocked updateTotalSessionTime for non-owner.');
      }
      return;
    }
    final docRef = _firestore.collection('users').doc(userId);

    await docRef.update({
      'totalSessionTime': FieldValue.increment(additionalSeconds),
    });
  }
}
