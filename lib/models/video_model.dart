class VideoModel {
  final String id;           // Firestore doc ID
  final String title;        // Video title
  final String youtubeId;    // YouTube video ID
  final String language;     // "en" or "si" (English/Sinhala)
  final int duration;        // Total duration in seconds (optional)
  final int session;         // Session number (1,2,3,...)
  final String description;  // Optional description

  VideoModel({
    required this.id,
    required this.title,
    required this.youtubeId,
    required this.language,
    this.duration = 0,
    this.session = 1,
    this.description = '',
  });

  /// Create VideoModel from Firestore map (Future Implementation)
  factory VideoModel.fromMap(Map<String, dynamic> map, String docId) {
    return VideoModel(
      id: docId,
      title: map['title'] ?? '',
      youtubeId: map['youtubeId'] ?? '',
      language: map['language'] ?? 'en',
      duration: map['duration'] ?? 0,
      session: map['session'] ?? 1,
      description: map['description'] ?? '',
    );
  }

  /// Convert VideoModel → Firestore map
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'youtubeId': youtubeId,
      'language': language,
      'duration': duration,
      'session': session,
      'description': description,
    };
  }
}
