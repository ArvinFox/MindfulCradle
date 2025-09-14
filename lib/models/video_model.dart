class VideoModel {
  final String id;
  final String title;
  final String description;
  final String videoUrl;

  VideoModel({
    required this.id,
    required this.title,
    required this.description,
    required this.videoUrl,
  });

  factory VideoModel.fromMap(Map<String, dynamic> map, String docId) {
    return VideoModel(
      id: docId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      videoUrl: map['videoUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'videoUrl': videoUrl,
    };
  }
}
