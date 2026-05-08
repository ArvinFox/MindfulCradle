import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/journal_entry.dart';

class JournalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _journalsRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('journals');

  Future<JournalEntry> addEntry({
    required String userId,
    required JournalEntry entry,
  }) async {
    final docRef = await _journalsRef(userId).add(entry.toMap());
    return JournalEntry(
      id: docRef.id,
      title: entry.title,
      content: entry.content,
      sentiment: entry.sentiment,
      sentimentScore: entry.sentimentScore,
      semanticTags: entry.semanticTags,
      createdAt: entry.createdAt,
      language: entry.language,
    );
  }

  Future<List<JournalEntry>> fetchEntries({required String userId}) async {
    try {
      final snap = await _journalsRef(
        userId,
      ).orderBy('createdAt', descending: true).get();
      return snap.docs.map(JournalEntry.fromFirestore).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> deleteEntry({
    required String userId,
    required String entryId,
  }) async {
    await _journalsRef(userId).doc(entryId).delete();
  }

  Future<void> updateSentiment({
    required String userId,
    required String entryId,
    required String sentiment,
    required double sentimentScore,
  }) async {
    await _journalsRef(userId).doc(entryId).update({
      'sentiment': sentiment,
      'sentimentScore': sentimentScore,
    });
  }
}
