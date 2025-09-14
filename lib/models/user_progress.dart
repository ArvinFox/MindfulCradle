class UserProgressModel {
  final String userId;
  final String videoId;
  final double progress; // 0.0 to 1.0
  final bool completed;

  UserProgressModel({
    required this.userId,
    required this.videoId,
    required this.progress,
    required this.completed,
  });

  factory UserProgressModel.fromMap(Map<String, dynamic> map) {
    return UserProgressModel(
      userId: map['userId'] ?? '',
      videoId: map['videoId'] ?? '',
      progress: (map['progress'] ?? 0.0).toDouble(),
      completed: map['completed'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'videoId': videoId,
      'progress': progress,
      'completed': completed,
    };
  }
}
