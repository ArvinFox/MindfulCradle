import 'package:cloud_firestore/cloud_firestore.dart';

class MoodEntry {
  final String id;
  final int moodIndex; // 0 (Very sad) → 4 (Very happy)
  final String? note;
  final DateTime createdAt;

  static const List<String> emojis = ['😢', '😟', '😐', '🙂', '😄'];
  static const List<String> labelsEn = [
    'Very Sad',
    'Sad',
    'Neutral',
    'Happy',
    'Very Happy',
  ];
  static const List<String> labelsSi = [
    'ඉතා දුකෙන්',
    'දුකෙන්',
    'සාමාන්‍යයෙන්',
    'සතුටෙන්',
    'ඉතා සතුටෙන්',
  ];

  const MoodEntry({
    required this.id,
    required this.moodIndex,
    this.note,
    required this.createdAt,
  });

  String get emoji => emojis[moodIndex.clamp(0, 4)];
  String labelEn() => labelsEn[moodIndex.clamp(0, 4)];
  String labelSi() => labelsSi[moodIndex.clamp(0, 4)];

  Map<String, dynamic> toMap() => {
    'moodIndex': moodIndex,
    'note': note,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  factory MoodEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MoodEntry(
      id: doc.id,
      moodIndex: (data['moodIndex'] as int? ?? 2).clamp(0, 4),
      note: data['note'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
