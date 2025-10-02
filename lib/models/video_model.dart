class VideoModel {
  final String id;
  final String title;
  final String youtubeId;
  final String youtubeIdSi; // For Sinhala Videos
  final int duration;
  final String language;
  final int sessionNumber;

  VideoModel({
    required this.id,
    required this.title,
    required this.youtubeId,
    required this.youtubeIdSi,
    required this.duration,
    required this.language,
    required this.sessionNumber,
  });

  factory VideoModel.fromMap(Map<String, dynamic> map, String docId) {
    return VideoModel(
      id: docId,
      title: map['title'] ?? '',
      youtubeId: map['youtubeId'] ?? '',
      youtubeIdSi: map['youtubeIdSi'] ?? '',
      duration: map['duration'] ?? 0,
      language: map['language'] ?? 'en',
      sessionNumber: map['sessionNumber'] ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'youtubeId': youtubeId,
      'youtubeIdSi': youtubeIdSi,
      'duration': duration,
      'language': language,
      'sessionNumber': sessionNumber,
    };
  }

  /// Helper to get the correct YouTube ID depending on app language
  String getYoutubeId(String currentLang) {
    if (currentLang == 'si' && youtubeIdSi.isNotEmpty) {
      return youtubeIdSi;
    }
    return youtubeId;
  }
}
