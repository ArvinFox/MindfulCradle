import 'package:cloud_firestore/cloud_firestore.dart';

class ChatSession {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int messageCount;

  ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.messageCount,
  });

  factory ChatSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatSession(
      id: doc.id,
      title: data['title'] as String? ?? 'Untitled Chat',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      messageCount: data['messageCount'] as int? ?? 0,
    );
  }
}

class ChatHistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a new chat session
  Future<String> createChatSession({
    required String userId,
    String? initialTitle,
  }) async {
    try {
      final docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('chat_sessions')
          .add({
            'title': initialTitle ?? 'New Chat',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'messageCount': 0,
          });
      return docRef.id;
    } catch (e) {
      print('Error creating chat session: $e');
      rethrow;
    }
  }

  /// Get all chat sessions for a user
  Future<List<ChatSession>> getChatSessions(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('chat_sessions')
          .orderBy('updatedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ChatSession.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error loading chat sessions: $e');
      return [];
    }
  }

  /// Save a message to a specific chat session
  Future<void> saveMessage({
    required String userId,
    required String sessionId,
    required String role,
    required String text,
  }) async {
    try {
      final batch = _firestore.batch();

      // Add message to session
      final messageRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('chat_sessions')
          .doc(sessionId)
          .collection('messages')
          .doc();

      batch.set(messageRef, {
        'role': role,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update session metadata
      final sessionRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('chat_sessions')
          .doc(sessionId);

      batch.update(sessionRef, {
        'updatedAt': FieldValue.serverTimestamp(),
        'messageCount': FieldValue.increment(1),
      });

      await batch.commit();
    } catch (e) {
      print('Error saving chat message: $e');
    }
  }

  /// Load messages from a specific chat session
  Future<List<Map<String, String>>> loadChatSession({
    required String userId,
    required String sessionId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('chat_sessions')
          .doc(sessionId)
          .collection('messages')
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
      print('Error loading chat session: $e');
      return [];
    }
  }

  /// Update chat session title (auto-generated from first message)
  Future<void> updateSessionTitle({
    required String userId,
    required String sessionId,
    required String title,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('chat_sessions')
          .doc(sessionId)
          .update({'title': title});
    } catch (e) {
      print('Error updating session title: $e');
    }
  }

  /// Delete a chat session
  Future<void> deleteChatSession({
    required String userId,
    required String sessionId,
  }) async {
    try {
      // Delete all messages first
      final messagesSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('chat_sessions')
          .doc(sessionId)
          .collection('messages')
          .get();

      final batch = _firestore.batch();
      for (var doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete the session document
      batch.delete(
        _firestore
            .collection('users')
            .doc(userId)
            .collection('chat_sessions')
            .doc(sessionId),
      );

      await batch.commit();
    } catch (e) {
      print('Error deleting chat session: $e');
    }
  }

  /// Generate title from first user message
  String generateTitleFromMessage(String message) {
    // Take first 30 characters or up to first sentence
    final sanitized = message.trim();
    if (sanitized.length <= 30) return sanitized;

    // Try to break at sentence end
    final sentenceEnd = sanitized.indexOf(RegExp(r'[.!?]'));
    if (sentenceEnd > 0 && sentenceEnd <= 40) {
      return sanitized.substring(0, sentenceEnd + 1);
    }

    // Otherwise just truncate
    return '${sanitized.substring(0, 30)}...';
  }
}
