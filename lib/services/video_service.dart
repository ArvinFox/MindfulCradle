import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mamamind/providers/video_provider.dart';
import '../models/video_model.dart';

class VideoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream all videos
  Stream<List<VideoModel>> streamAllVideos() {
    return _firestore
        .collection('videos')
        .orderBy('sessionNumber')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => VideoModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  /// Save user progress
  Future<void> saveVideoProgress({
    required String userId,
    required String videoId,
    required int watchedSeconds,
  }) async {
    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('videoProgress')
        .doc(videoId);

    final doc = await docRef.get();
    if (doc.exists) {
      final prevSeconds = doc['watchedSeconds'] ?? 0;
      final newSeconds = watchedSeconds > prevSeconds
          ? watchedSeconds
          : prevSeconds;
      await docRef.update({
        'watchedSeconds': newSeconds,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await docRef.set({
        'watchedSeconds': watchedSeconds,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Stream user progress
  Stream<Map<String, int>> streamUserProgress(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('videoProgress')
        .snapshots()
        .map((snapshot) {
          final Map<String, int> progress = {};
          for (var doc in snapshot.docs) {
            progress[doc.id] = doc['watchedSeconds'] ?? 0;
          }
          return progress;
        });
  }

  /// Update unlocked videos in Firestore
  Future<void> updateUnlockedVideos(String userId, List<int> unlockedSessions) async {
    await _firestore.collection('users').doc(userId).update({
      'unlockedVideos': unlockedSessions,
    });
  }
}

/// Video language pass
extension VideoProviderLang on VideoProvider {
  String getVideoYoutubeId(VideoModel video, String currentLang) {
    return video.getYoutubeId(currentLang);
  }
}
