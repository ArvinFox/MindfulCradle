class UserModel {
  final String id;
  final String fullName;
  final String email;
  final List<String> achievements;
  final List<int> unlockedVideos;
  final int totalSessionTime;
  final int videoWatchTime;
  final bool isUserRegistrationComplete;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.achievements,
    required this.unlockedVideos,
    required this.totalSessionTime,
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
      videoWatchTime: 0,
      isUserRegistrationComplete: false,
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String docId) {
    final rawWatchTime = map['videoWatchTime'];
    int resolvedWatchTime = 0;
    if (rawWatchTime is int) {
      resolvedWatchTime = rawWatchTime;
    } else if (rawWatchTime is Map) {
      for (final value in rawWatchTime.values) {
        if (value is int) {
          resolvedWatchTime += value;
        }
      }
    }

    return UserModel(
      id: docId,
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      achievements: List<String>.from(map['achievements'] ?? []),
      unlockedVideos: List<int>.from(map['unlockedVideos'] ?? []),
      totalSessionTime: map['totalSessionTime'] ?? 0,
      videoWatchTime: resolvedWatchTime,
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
      'videoWatchTime': videoWatchTime,
      'isUserRegistrationComplete': isUserRegistrationComplete,
    };
  }

  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    List<String>? achievements,
    List<int>? unlockedVideos,
    int? totalSessionTime,
    int? videoWatchTime,
    bool? isUserRegistrationComplete,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      achievements: achievements ?? this.achievements,
      unlockedVideos: unlockedVideos ?? this.unlockedVideos,
      totalSessionTime: totalSessionTime ?? this.totalSessionTime,
      videoWatchTime: videoWatchTime ?? this.videoWatchTime,
      isUserRegistrationComplete:
          isUserRegistrationComplete ?? this.isUserRegistrationComplete,
    );
  }
}
