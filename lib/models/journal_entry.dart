import 'package:cloud_firestore/cloud_firestore.dart';

class JournalEntry {
  final String id;
  final String title;
  final String content;
  final String sentiment; // 'positive', 'neutral', 'negative'
  final double sentimentScore; // -1.0 to 1.0
  final List<String> semanticTags;
  final DateTime createdAt;
  final String language; // 'en' or 'si'

  const JournalEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.sentiment,
    required this.sentimentScore,
    required this.semanticTags,
    required this.createdAt,
    required this.language,
  });

  Map<String, dynamic> toMap() => {
    'title': title,
    'content': content,
    'sentiment': sentiment,
    'sentimentScore': sentimentScore,
    'semanticTags': semanticTags,
    'createdAt': Timestamp.fromDate(createdAt),
    'language': language,
  };

  factory JournalEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return JournalEntry(
      id: doc.id,
      title: data['title'] as String? ?? '',
      content: data['content'] as String? ?? '',
      sentiment: data['sentiment'] as String? ?? 'neutral',
      sentimentScore: (data['sentimentScore'] as num?)?.toDouble() ?? 0.0,
      semanticTags: List<String>.from(data['semanticTags'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      language: data['language'] as String? ?? 'en',
    );
  }
}
