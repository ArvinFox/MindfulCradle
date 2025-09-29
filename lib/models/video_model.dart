class VideoModel {
  final String id;
  final String title;
  final String youtubeId;
  final int duration;
  final String language;
  final int sessionNumber;

  VideoModel({
    required this.id,
    required this.title,
    required this.youtubeId,
    required this.duration,
    required this.language,
    required this.sessionNumber,
  });

  factory VideoModel.fromMap(Map<String, dynamic> map, String docId) {
    return VideoModel(
      id: docId,
      title: map['title'] ?? '',
      youtubeId: map['youtubeId'] ?? '',
      duration: map['duration'] ?? 0,
      language: map['language'] ?? 'en',
      sessionNumber: map['sessionNumber'] ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'youtubeId': youtubeId,
      'duration': duration,
      'language': language,
      'sessionNumber': sessionNumber,
    };
  }
}
