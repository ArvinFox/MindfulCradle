import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Increment total session time for a user
  Future<void> updateTotalSessionTime({
    required String userId,
    required int additionalSeconds,
  }) async {
    final docRef = _firestore.collection('users').doc(userId);

    await docRef.update({
      'totalSessionTime': FieldValue.increment(additionalSeconds),
    });
  }
}
