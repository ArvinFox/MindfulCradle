class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String? photoUrl;
  final List<String> achievements;
  final List<int> unlockedVideos;
  final int totalSessionTime;
  final int videoWatchTime;
  final bool isUserRegistrationComplete;
  final bool isTutorialDone;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.photoUrl,
    required this.achievements,
    required this.unlockedVideos,
    required this.totalSessionTime,
    required this.videoWatchTime,
    required this.isUserRegistrationComplete,
    this.isTutorialDone = true,
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
      isTutorialDone: false,
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
      fullName: map['fullName'] as String? ?? '',
      email: map['email'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
      achievements: List<String>.from(map['achievements'] ?? []),
      unlockedVideos: List<int>.from(map['unlockedVideos'] ?? []),
      totalSessionTime: map['totalSessionTime'] as int? ?? 0,
      videoWatchTime: resolvedWatchTime,
      isUserRegistrationComplete:
          map['isUserRegistrationComplete'] as bool? ?? false,
      // Default true for existing users who don't have this field yet
      isTutorialDone: map['isTutorialDone'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      if (photoUrl != null) 'photoUrl': photoUrl,
      'achievements': achievements,
      'unlockedVideos': unlockedVideos,
      'totalSessionTime': totalSessionTime,
      'videoWatchTime': videoWatchTime,
      'isUserRegistrationComplete': isUserRegistrationComplete,
      'isTutorialDone': isTutorialDone,
    };
  }

  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? photoUrl,
    List<String>? achievements,
    List<int>? unlockedVideos,
    int? totalSessionTime,
    int? videoWatchTime,
    bool? isUserRegistrationComplete,
    bool? isTutorialDone,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      achievements: achievements ?? this.achievements,
      unlockedVideos: unlockedVideos ?? this.unlockedVideos,
      totalSessionTime: totalSessionTime ?? this.totalSessionTime,
      videoWatchTime: videoWatchTime ?? this.videoWatchTime,
      isUserRegistrationComplete:
          isUserRegistrationComplete ?? this.isUserRegistrationComplete,
      isTutorialDone: isTutorialDone ?? this.isTutorialDone,
    );
  }
}
