import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String _userIdKey = 'userId';

  UserModel? _user;
  bool _isInitializing = true;
  bool _isLoading = false;
  bool _initialized = false;

  StreamSubscription<DocumentSnapshot>? _userSub;
  Timer? _sessionTimer;
  DateTime? _sessionStartedAt;
  DateTime? _lastSessionTick;
  bool _sessionActive = false;

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
        _startSessionTracking(doc.id);
      } else {
        _user = null;
        _stopSessionTracking(flush: false);
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
      await _stopSessionTracking(flush: true);
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

  void _startSessionTracking(String userId) {
    if (_sessionActive) return;
    _sessionActive = true;
    _sessionStartedAt = DateTime.now();
    _lastSessionTick = _sessionStartedAt;
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _flushSessionTime(userId),
    );
  }

  Future<void> _flushSessionTime(String userId) async {
    if (!_sessionActive) return;
    final now = DateTime.now();
    final last = _lastSessionTick ?? _sessionStartedAt ?? now;
    final delta = now.difference(last).inSeconds;
    _lastSessionTick = now;
    if (delta <= 0) return;
    await _userService.updateTotalSessionTime(
      userId: userId,
      additionalSeconds: delta,
    );
  }

  Future<void> _stopSessionTracking({required bool flush}) async {
    final userId = _user?.id;
    _sessionTimer?.cancel();
    _sessionTimer = null;

    if (flush && userId != null) {
      final now = DateTime.now();
      final last = _lastSessionTick ?? _sessionStartedAt ?? now;
      final delta = now.difference(last).inSeconds;
      if (delta > 0) {
        await _userService.updateTotalSessionTime(
          userId: userId,
          additionalSeconds: delta,
        );
      }
    }

    _sessionActive = false;
    _sessionStartedAt = null;
    _lastSessionTick = null;
  }

  Future<void> handleAppLifecycle(AppLifecycleState state) async {
    if (_user == null) return;
    if (state == AppLifecycleState.resumed) {
      _startSessionTracking(_user!.id);
      return;
    }

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      await _stopSessionTracking(flush: true);
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

  /// Delete user account (GDPR compliance)
  /// Requires re-authentication for security
  Future<String?> deleteAccount(
    String password, {
    String langCode = 'en',
  }) async {
    if (_user == null) {
      return langCode == 'si'
          ? 'පරිශීලක හඳුනාගත නොහැකි විය.'
          : 'User not identified.';
    }

    _isLoading = true;
    notifyListeners();

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null || currentUser.email == null) {
        return langCode == 'si'
            ? 'පරිශීලක හඳුනාගත නොහැකි විය.'
            : 'User not identified.';
      }

      // Re-authenticate user for security
      final credential = EmailAuthProvider.credential(
        email: currentUser.email!,
        password: password,
      );

      await currentUser.reauthenticateWithCredential(credential);

      final userId = currentUser.uid;

      // Delete all user data from Firestore subcollections
      final userDoc = _firestore.collection('users').doc(userId);

      // Delete dass21_responses subcollection
      final dass21Snapshot = await userDoc.collection('dass21_responses').get();
      for (var doc in dass21Snapshot.docs) {
        await doc.reference.delete();
      }

      // Delete pws18_responses subcollection
      final pws18Snapshot = await userDoc.collection('pws18_responses').get();
      for (var doc in pws18Snapshot.docs) {
        await doc.reference.delete();
      }

      // Delete maas_responses subcollection
      final maasSnapshot = await userDoc.collection('maas_responses').get();
      for (var doc in maasSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete videoProgress subcollection
      final videoSnapshot = await userDoc.collection('videoProgress').get();
      for (var doc in videoSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete main user document
      await userDoc.delete();

      // Delete Firebase Auth user
      await currentUser.delete();

      // Clear local storage
      await _secureStorage.delete(key: _userIdKey);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userIdKey);

      // Cancel subscription and clear user
      _userSub?.cancel();
      _userSub = null;
      _user = null;

      return null; // Success
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        return langCode == 'si' ? 'මුරපදය වැරදියි.' : 'Incorrect password.';
      } else if (e.code == 'requires-recent-login') {
        return langCode == 'si'
            ? 'කරුණාකර නැවත ඇතුළු වී උත්සාහ කරන්න.'
            : 'Please login again and try.';
      }
      return langCode == 'si'
          ? 'ගිණුම මකා දැමීම අසාර්ථකයි.'
          : 'Account deletion failed.';
    } catch (e) {
      if (kDebugMode) debugPrint("Delete account error: $e");
      return langCode == 'si'
          ? 'ගිණුම මකා දැමීම අසාර්ථකයි.'
          : 'Account deletion failed.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Export user data as CSV (GDPR Right to Portability)
  Future<String?> exportUserDataCsv({String langCode = 'en'}) async {
    final rows = await exportUserDataRows(langCode: langCode);
    if (rows == null || rows.isEmpty) {
      return null;
    }

    return rowsToCsv(rows);
  }

  /// Export user data as rows for preview
  Future<List<List<String>>?> exportUserDataRows({
    String langCode = 'en',
  }) async {
    if (_user == null) {
      return null;
    }

    try {
      final userId = _user!.id;
      final userDoc = _firestore.collection('users').doc(userId);

      final rows = <List<String>>[];
      rows.add(['Section', 'Record', 'Field', 'Value']);

      // Export metadata
      rows.add([
        'Meta',
        'export',
        'export_date',
        DateTime.now().toIso8601String(),
      ]);

      // User profile
      _addMapToRows(rows, 'Profile', 'user', _user!.toMap());

      // dass21 responses
      final dass21Snapshot = await userDoc.collection('dass21_responses').get();
      for (final doc in dass21Snapshot.docs) {
        _addMapToRows(rows, 'DASS21', doc.id, doc.data());
      }

      // pws18 responses
      final pws18Snapshot = await userDoc.collection('pws18_responses').get();
      for (final doc in pws18Snapshot.docs) {
        _addMapToRows(rows, 'PWS18', doc.id, doc.data());
      }

      // maas responses
      final maasSnapshot = await userDoc.collection('maas_responses').get();
      for (final doc in maasSnapshot.docs) {
        _addMapToRows(rows, 'MAAS', doc.id, doc.data());
      }

      // video progress
      final videoSnapshot = await userDoc.collection('videoProgress').get();
      for (final doc in videoSnapshot.docs) {
        _addMapToRows(rows, 'VideoProgress', doc.id, doc.data());
      }

      return rows;
    } catch (e) {
      if (kDebugMode) debugPrint("Export data error: $e");
      return null;
    }
  }

  String rowsToCsv(List<List<String>> rows) {
    final lines = rows.map((row) => row.map(_csvEscape).join(',')).toList();
    return lines.join('\n');
  }

  void _addMapToRows(
    List<List<String>> rows,
    String section,
    String recordId,
    Map<String, dynamic> data,
  ) {
    for (final entry in data.entries) {
      final value = entry.value is Map || entry.value is List
          ? entry.value.toString()
          : entry.value;
      rows.add([section, recordId, entry.key, value.toString()]);
    }
  }

  String _csvEscape(Object? value) {
    final text = value?.toString() ?? '';
    final needsQuotes =
        text.contains(',') || text.contains('"') || text.contains('\n');
    if (!needsQuotes) return text;
    final escaped = text.replaceAll('"', '""');
    return '"$escaped"';
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
