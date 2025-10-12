class UserModel {
  final String id;
  final String fullName;
  final String email;
  final List<String> achievements;
  final List<int> unlockedVideos;
  final int totalSessionTime;
  final Map<String, int> videoProgress;
  final Map<String, int> videoWatchTime;
  final bool isUserRegistrationComplete;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.achievements,
    required this.unlockedVideos,
    required this.totalSessionTime,
    required this.videoProgress,
    required this.videoWatchTime,
    required this.isUserRegistrationComplete,
  });

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
      unlockedVideos: [1],
      totalSessionTime: 0,
      videoProgress: {},
      videoWatchTime: {},
      isUserRegistrationComplete: false,
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String docId) {
    return UserModel(
      id: docId,
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      achievements: List<String>.from(map['achievements'] ?? []),
      unlockedVideos: List<int>.from(map['unlockedVideos'] ?? []),
      totalSessionTime: map['totalSessionTime'] ?? 0,
      videoProgress: Map<String, int>.from(map['videoProgress'] ?? {}),
      videoWatchTime: Map<String, int>.from(map['videoWatchTime'] ?? {}),
      isUserRegistrationComplete: map['isUserRegistrationComplete'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'achievements': achievements,
      'unlockedVideos': unlockedVideos,
      'totalSessionTime': totalSessionTime,
      'videoProgress': videoProgress,
      'videoWatchTime': videoWatchTime,
      'isUserRegistrationComplete': isUserRegistrationComplete,
    };
  }
}
