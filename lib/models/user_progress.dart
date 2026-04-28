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

  factory UserProgressModel.initial({
    required String userId,
    required String videoId,
  }) {
    return UserProgressModel(
      userId: userId,
      videoId: videoId,
      progress: 0.0,
      completed: false,
    );
  }

  factory UserProgressModel.fromMap(Map<String, dynamic> map) {
    return UserProgressModel(
      userId: map['userId'] as String? ?? '',
      videoId: map['videoId'] as String? ?? '',
      progress: (map['progress'] as num?)?.toDouble() ?? 0.0,
      completed: map['completed'] as bool? ?? false,
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
