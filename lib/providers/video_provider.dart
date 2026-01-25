import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/video_model.dart';
import '../models/user_model.dart';
import '../services/video_service.dart';
import '../providers/achievement_provider.dart';

class VideoProvider with ChangeNotifier {
  final VideoService _videoService = VideoService();

  List<VideoModel> _videos = [];
  Map<String, int> _userProgress = {};
  UserModel? _user;

  StreamSubscription<Map<String, int>>? _progressSub;
  StreamSubscription<List<VideoModel>>? _videosSub;
  Completer<void>? _firstProgressCompleter;

  List<VideoModel> get videos => _videos;
  Map<String, int> get userProgress => _userProgress;
  UserModel? get user => _user;

  /// Set current user and start listening to videos & progress
  void setUser(UserModel user, BuildContext context) {
    // Accept Context to find AchievementProvider
    _progressSub?.cancel();
    _videosSub?.cancel();

    _user = user;
    _userProgress.clear();

    _firstProgressCompleter = Completer();

    // Listen to user progress
    _progressSub = _videoService.streamUserProgress(user.id).listen((progress) {
      _userProgress = progress;
      _checkUnlocks(context);
      notifyListeners();

      _firstProgressCompleter?.complete();
    });

    // Listen to videos live
    _videosSub = _videoService.streamAllVideos().listen((videos) {
      _videos = videos;
      _checkUnlocks(context);
      notifyListeners();
    });

    notifyListeners();
  }

  /// Wait for first progress snapshot
  Future<void> waitForInitialProgress() async {
    if (_firstProgressCompleter != null) {
      await _firstProgressCompleter!.future;
    }
  }

  /// Update watched seconds for the user & video
  Future<void> updateProgress({
    required BuildContext context,
    required String userId,
    required String videoId,
    required int watchedSeconds,
  }) async {
    if (_user == null) return;

    final current = _userProgress[videoId] ?? 0;
    if (watchedSeconds > current) {
      _userProgress[videoId] = watchedSeconds;
      await _videoService.saveVideoProgress(
        userId: userId,
        videoId: videoId,
        watchedSeconds: watchedSeconds,
      );
      // We don't await this so it doesn't block the UI loop
      _checkUnlocks(context);
      notifyListeners();
    }
  }

  /// Unlock logic (90% watched) + Achievement Logic
  Future<void> _checkUnlocks(BuildContext context) async {
    if (_user == null || _videos.isEmpty) return;
    bool updated = false;

    // Video Unlocking Logic (Sequential Access)
    for (int i = 1; i < _videos.length; i++) {
      final prevVideo = _videos[i - 1];
      final nextVideo = _videos[i];
      final watched = _userProgress[prevVideo.id] ?? 0;

      if (watched >= ((prevVideo.duration * 0.9).ceil()) &&
          !_user!.unlockedVideos.contains(nextVideo.sessionNumber)) {
        _user!.unlockedVideos.add(nextVideo.sessionNumber);
        updated = true;
      }
    }

    // Save unlocked videos to Firestore
    if (updated) {
      await _videoService.updateUnlockedVideos(
        _user!.id,
        _user!.unlockedVideos,
      );
    }

    // ACHIEVEMENT LOGIC: Count total completed videos
    int completedCount = 0;
    for (var video in _videos) {
      final watched = _userProgress[video.id] ?? 0;
      // If watched more than 90%, it counts as complete
      if (watched >= ((video.duration * 0.9).ceil())) {
        completedCount++;
      }
    }

    try {
      if (context.mounted) {
        final achievementProvider = Provider.of<AchievementProvider>(
          context,
          listen: false,
        );

        // Badge 1: First Step
        if (completedCount >= 1) {
          await achievementProvider.unlockAchievement(
            context,
            'first_step',
            showUI: false,
          );
        }

        // Badge 2: Halfway There
        if (completedCount >= 4) {
          await achievementProvider.unlockAchievement(
            context,
            'halfway_there',
            showUI: false,
          );
        }

        // Badge 3: Zen Master
        if (completedCount >= 8) {
          await achievementProvider.unlockAchievement(
            context,
            'zen_master',
            showUI: false,
          );
        }
      }
    } catch (e) {
      debugPrint("Error updating achievements in VideoProvider: $e");
    }
  }

  /// Check if video is unlocked
  bool isVideoUnlocked(VideoModel video) {
    if (video.sessionNumber == 1) return true;
    if (_user == null) return false;
    if (_user!.unlockedVideos.contains(video.sessionNumber)) return true;

    final index = _videos.indexWhere((v) => v.id == video.id);
    if (index == 0) return true;

    final prevVideo = _videos[index - 1];
    final prevWatched = _userProgress[prevVideo.id] ?? 0;

    return prevWatched >= ((prevVideo.duration * 0.9).ceil());
  }

  /// Get last watched seconds for this user & video
  int getLastWatchedSecond(String videoId) {
    return _userProgress[videoId] ?? 0;
  }

  /// Reset provider (on logout)
  void reset() {
    _user = null;
    _videos = [];
    _userProgress.clear();
    _progressSub?.cancel();
    _videosSub?.cancel();
    _progressSub = null;
    _videosSub = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _progressSub?.cancel();
    _videosSub?.cancel();
    super.dispose();
  }
}
