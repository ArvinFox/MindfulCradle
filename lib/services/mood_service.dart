import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/mood_entry.dart';

class MoodService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _moodsRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('moods');

  Future<MoodEntry> addEntry({
    required String userId,
    required MoodEntry entry,
  }) async {
    final docRef = await _moodsRef(userId).add(entry.toMap());
    return MoodEntry(
      id: docRef.id,
      moodIndex: entry.moodIndex,
      note: entry.note,
      createdAt: entry.createdAt,
    );
  }

  Future<List<MoodEntry>> fetchEntries({
    required String userId,
    int limit = 30,
  }) async {
    try {
      final snap = await _moodsRef(
        userId,
      ).orderBy('createdAt', descending: true).limit(limit).get();
      return snap.docs.map(MoodEntry.fromFirestore).toList();
    } catch (_) {
      return [];
    }
  }

  /// Returns today's mood entry if it exists, else null.
  Future<MoodEntry?> fetchTodayMood({required String userId}) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    try {
      final snap = await _moodsRef(userId)
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where('createdAt', isLessThan: Timestamp.fromDate(endOfDay))
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;
      return MoodEntry.fromFirestore(snap.docs.first);
    } catch (_) {
      return null;
    }
  }
}
