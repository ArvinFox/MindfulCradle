class VideoModel {
  final String id;
  final String title;
  final String titleSi;
  final String youtubeId;
  final String youtubeIdSi; // For Sinhala Videos
  final int duration;
  final int sessionNumber;

  VideoModel({
    required this.id,
    required this.title,
    required this.titleSi,
    required this.youtubeId,
    required this.youtubeIdSi,
    required this.duration,
    required this.sessionNumber,
  });

  factory VideoModel.fromMap(Map<String, dynamic> map, String docId) {
    return VideoModel(
      id: docId,
      title: map['title'] ?? '',
      titleSi: map['titleSi'] ?? '',
      youtubeId: map['youtubeId'] ?? '',
      youtubeIdSi: map['youtubeIdSi'] ?? '',
      duration: map['duration'] ?? 0,
      sessionNumber: map['sessionNumber'] ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'titleSi': titleSi,
      'youtubeId': youtubeId,
      'youtubeIdSi': youtubeIdSi,
      'duration': duration,
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
