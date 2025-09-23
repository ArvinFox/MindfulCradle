class UserModel {
  final String id;
  final String fullName;
  final String email;
  final List<String> achievements;
  final List<int> unlockedVideos;
  final List<int> lockedVideos;

  /// Total meditation time in minutes (or seconds if you prefer)
  final int totalSessionTime;

  /// Map of videoId -> last watched seconds (resume point)
  final Map<String, int> videoProgress;

  /// Map of videoId -> total watched time in seconds (for stats)
  final Map<String, int> videoWatchTime;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.achievements,
    required this.unlockedVideos,
    required this.lockedVideos,
    required this.totalSessionTime,
    required this.videoProgress,
    required this.videoWatchTime,
  });

  /// Factory for creating a new user with defaults
  factory UserModel.newUser({
    required String id,
    required String fullName,
    required String email,
  }) {
    return UserModel(
      id: id,
      fullName: fullName,
      email: email,
      achievements: [],
      unlockedVideos: [1], // First video unlocked
      lockedVideos: [2, 3, 4, 5, 6, 7, 8],
      totalSessionTime: 0,
      videoProgress: {},
      videoWatchTime: {},
    );
  }

  /// Firestore -> UserModel
  factory UserModel.fromMap(Map<String, dynamic> map, String docId) {
    return UserModel(
      id: docId,
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      achievements: List<String>.from(map['achievements'] ?? []),
      unlockedVideos: List<int>.from(map['unlockedVideos'] ?? []),
      lockedVideos: List<int>.from(map['lockedVideos'] ?? []),
      totalSessionTime: map['totalSessionTime'] ?? 0,
      videoProgress: Map<String, int>.from(map['videoProgress'] ?? {}),
      videoWatchTime: Map<String, int>.from(map['videoWatchTime'] ?? {}),
    );
  }

  /// UserModel -> Firestore
  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'achievements': achievements,
      'unlockedVideos': unlockedVideos,
      'lockedVideos': lockedVideos,
      'totalSessionTime': totalSessionTime,
      'videoProgress': videoProgress,
      'videoWatchTime': videoWatchTime,
    };
  }
}
