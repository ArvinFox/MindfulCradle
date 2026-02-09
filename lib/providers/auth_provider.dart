import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String _userIdKey = 'userId';

  UserModel? _user;
  bool _isInitializing = true;
  bool _isLoading = false;
  bool _initialized = false;

  StreamSubscription<DocumentSnapshot>? _userSub;

  UserModel? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isInitializing => _isInitializing;
  bool get isLoading => _isLoading;

  /// Load user from shared preferences
  Future<void> loadUserFromPrefs() async {
    if (_initialized) return;

    _isInitializing = true;
    notifyListeners();

    try {
      final uid = await _readUserIdFromStorage();

      if (uid != null) {
        _listenToUser(uid);
      }
    } catch (e) {
      if (kDebugMode) debugPrint("Error loading user.");
    } finally {
      _isInitializing = false;
      _initialized = true;
      notifyListeners();
    }
  }

  /// Start listening to Firestore user doc
  void _listenToUser(String uid) {
    _userSub?.cancel();
    _userSub = _firestore.collection('users').doc(uid).snapshots().listen((
      doc,
    ) {
      if (doc.exists) {
        _user = UserModel.fromMap(doc.data()!, doc.id);
      } else {
        _user = null;
      }
      notifyListeners();
    });
  }

  /// Login user
  Future<String?> login(
    String email,
    String password, {
    bool rememberMe = false,
    String langCode = 'en',
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _authService
          .login(email: email, password: password, langCode: langCode)
          .timeout(const Duration(seconds: 20));

      if (result == null) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          if (rememberMe) {
            await _secureStorage.write(key: _userIdKey, value: user.uid);
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove(_userIdKey);
          }
          _listenToUser(user.uid);
        }
      }

      return result;
    } on TimeoutException {
      return langCode == 'si'
          ? 'සම්බන්ධතාවය ප්‍රමාද වී ඇත. කරුණාකර නැවත උත්සාහ කරන්න.'
          : 'Connection timed out. Please try again.';
    } catch (e) {
      return langCode == 'si'
          ? 'සත්‍යාපනය අසාර්ථකයි. කරුණාකර නැවත උත්සාහ කරන්න.'
          : 'Authentication failed. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Logout user
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signOut();
      _user = null;

      await _secureStorage.delete(key: _userIdKey);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userIdKey);
      _userSub?.cancel();
      _userSub = null;
    } catch (e) {
      if (kDebugMode) debugPrint("Logout error.");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void addLocalAchievement(String achievementId) {
    if (_user != null && !_user!.achievements.contains(achievementId)) {
      final updatedList = List<String>.from(_user!.achievements)
        ..add(achievementId);

      _user = _user!.copyWith(achievements: updatedList);

      notifyListeners();
    }
  }

  Future<String?> _readUserIdFromStorage() async {
    final fromSecure = await _secureStorage.read(key: _userIdKey);
    if (fromSecure != null && fromSecure.isNotEmpty) {
      return fromSecure;
    }

    final prefs = await SharedPreferences.getInstance();
    final fromPrefs = prefs.getString(_userIdKey);
    if (fromPrefs != null && fromPrefs.isNotEmpty) {
      await _secureStorage.write(key: _userIdKey, value: fromPrefs);
      await prefs.remove(_userIdKey);
      return fromPrefs;
    }

    return null;
  }
}
