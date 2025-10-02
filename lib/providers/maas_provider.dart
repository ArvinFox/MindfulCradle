import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class MAASProvider with ChangeNotifier {
  UserModel? _user;

  List<int?> responses = List<int?>.filled(15, null); // 15 questions

  double? latestMAASScore;
  String? latestMAASClassification;

  MAASProvider();

  UserModel? get user => _user;

  void setUser(UserModel user) {
    _user = user;
    notifyListeners();
  }

  void setAnswer(int questionId, int value) {
    responses[questionId - 1] = value;
    notifyListeners();
  }

  bool get allAnswered => !responses.contains(null);

  /// Calculate the MAAS score as the **average of all responses**
  double calculateMAASScore() {
    final total = responses.fold<int>(0, (sum, val) => sum + (val ?? 0));
    return total / responses.length;
  }

  /// Classify the score according to your thresholds
  String classifyScore(double score) {
    if (score >= 4.0) {
      return 'High Mindful Attention';
    } else if (score >= 3.0) {
      return 'Average Mindful Attention';
    } else {
      return 'Low Mindful Attention';
    }
  }

  /// Save current responses to Firebase
  Future<void> saveToFirebase(BuildContext context) async {
    if (!allAnswered) return;

    final maasScore = calculateMAASScore();

    final responseMap = Map.fromIterables(
      List.generate(15, (i) => (i + 1).toString()),
      responses.map((e) => e ?? 0),
    );

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = _user ?? authProvider.user;
    if (currentUser == null) throw Exception("User not found");

    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.id)
        .collection('maas_responses')
        .doc('latest')
        .set({
      'responses': responseMap,
      'maasScore': maasScore,
      'classification': classifyScore(maasScore),
      'completedAt': FieldValue.serverTimestamp(),
    });

    // Update latest values locally
    latestMAASScore = maasScore;
    latestMAASClassification = classifyScore(maasScore);
    notifyListeners();
  }

  /// Load the latest MAAS response from Firebase
  Future<void> loadLatestResponse() async {
    if (_user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.id)
          .collection('maas_responses')
          .doc('latest')
          .get();

      if (doc.exists) {
        final data = doc.data();
        latestMAASScore = (data?['maasScore'] as num?)?.toDouble();
        latestMAASClassification = data?['classification'] as String?;
      } else {
        latestMAASScore = null;
        latestMAASClassification = null;
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print("Error loading latest MAAS response: $e");
    }
  }

  /// Reset everything
  void reset() {
    _user = null;
    responses = List<int?>.filled(15, null);
    latestMAASScore = null;
    latestMAASClassification = null;
    notifyListeners();
  }
}
