import 'package:cloud_firestore/cloud_firestore.dart';

class ChatHistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Save a message to Firestore
  Future<void> saveMessage({
    required String userId,
    required String role,
    required String text,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('chat_history')
          .add({
            'role': role,
            'text': text,
            'timestamp': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      print('Error saving chat message: $e');
    }
  }

  /// Load chat history for a user
  Future<List<Map<String, String>>> loadChatHistory(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('chat_history')
          .orderBy('timestamp', descending: false)
          .get();

      return snapshot.docs
          .map(
            (doc) => {
              'role': doc['role'] as String? ?? '',
              'text': doc['text'] as String? ?? '',
            },
          )
          .toList();
    } catch (e) {
      print('Error loading chat history: $e');
      return [];
    }
  }

  /// Clear all chat history for a user
  Future<void> clearChatHistory(String userId) async {
    try {
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('chat_history')
          .get();

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('Error clearing chat history: $e');
    }
  }
}
