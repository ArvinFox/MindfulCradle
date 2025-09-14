class AchievementModel {
  final String id;
  final String title;
  final String description;
  final String icon; // could be emoji or asset path

  AchievementModel({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
  });

  factory AchievementModel.fromMap(Map<String, dynamic> map, String docId) {
    return AchievementModel(
      id: docId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      icon: map['icon'] ?? '⭐',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'icon': icon,
    };
  }
}
