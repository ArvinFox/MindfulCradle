import 'dart:async';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class AppSessionProvider extends ChangeNotifier with WidgetsBindingObserver {
  final UserService _userService = UserService();

  UserModel? _user;
  int _sessionSeconds = 0;
  Timer? _timer;

  bool _isActive = false;

  int get sessionSeconds => _sessionSeconds;

  /// Set current user
  void setUser(UserModel user) {
    _user = user;
    _sessionSeconds = 0; // start fresh for this session
    _startTimer();
    WidgetsBinding.instance.addObserver(this);
  }

  /// App lifecycle events
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_user == null) return;

    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _pauseTimer();
    } else if (state == AppLifecycleState.resumed) {
      _resumeTimer();
    }
  }

  /// Start timer
  void _startTimer() {
    _isActive = true;
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (_isActive) {
        _sessionSeconds += 1;

        // Update Firestore every 60 seconds
        if (_sessionSeconds % 60 == 0 && _user != null) {
          await _userService.updateTotalSessionTime(
            userId: _user!.id,
            additionalSeconds: 60,
          );
        }
      }
    });
  }

  /// Pause timer
  void _pauseTimer() {
    _isActive = false;
  }

  /// Resume timer
  void _resumeTimer() {
    _isActive = true;
  }

  /// Stop timer and save total session time (on logout)
  Future<void> stopAndSave() async {
    _timer?.cancel();
    if (_user != null && _sessionSeconds > 0) {
      await _userService.updateTotalSessionTime(
        userId: _user!.id,
        additionalSeconds: _sessionSeconds,
      );
    }
    _sessionSeconds = 0;
    _user = null;
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
