class UserModel {
  final String id;
  final String fullName;
  final String email;
  final List<String> achievements;
  final List<int> unlockedVideos;
  final List<int> lockedVideos;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.achievements,
    required this.unlockedVideos,
    required this.lockedVideos,
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
      unlockedVideos: [1], // Only first video unlocked
      lockedVideos: [2, 3, 4, 5, 6, 7, 8],
    );
  }

  /// Convert Firestore map → UserModel
  factory UserModel.fromMap(Map<String, dynamic> map, String docId) {
    return UserModel(
      id: docId,
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      achievements: List<String>.from(map['achievements'] ?? []),
      unlockedVideos: List<int>.from(map['unlockedVideos'] ?? []),
      lockedVideos: List<int>.from(map['lockedVideos'] ?? []),
    );
  }

  /// Convert UserModel → Firestore map
  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'achievements': achievements,
      'unlockedVideos': unlockedVideos,
      'lockedVideos': lockedVideos,
    };
  }
}
