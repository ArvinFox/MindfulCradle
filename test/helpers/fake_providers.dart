// Shared test helpers: fake Provider implementations that don't touch Firebase.

import 'package:flutter/material.dart';
import 'package:mamamind/models/user_model.dart';
import 'package:mamamind/providers/auth_provider.dart';
import 'package:mamamind/providers/language_provider.dart';

/// A minimal LanguageProvider that always reports English and never
/// touches SharedPreferences or the notification service.
class FakeLanguageProvider extends ChangeNotifier implements LanguageProvider {
  String _lang;

  FakeLanguageProvider({String lang = 'en'}) : _lang = lang;

  @override
  String get currentLang => _lang;

  @override
  Future<void> setLanguage(String lang) async {
    _lang = lang;
    notifyListeners();
  }
}

/// A minimal AuthProvider that avoids all Firebase calls.
/// Stub the responses you need per test via the constructor parameters.
class FakeAuthProvider extends ChangeNotifier implements AuthProvider {
  // noSuchMethod makes the compiler happy for any AuthProvider method
  // not explicitly overridden below. Those methods will throw at runtime
  // only if they are actually called during a test.
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  final bool _isInitializing;
  final bool _isLoading;
  final UserModel? _user;
  final String? _loginResult;

  FakeAuthProvider({
    bool isInitializing = false,
    bool isLoading = false,
    UserModel? user,
    String? loginResult,
  }) : _isInitializing = isInitializing,
       _isLoading = isLoading,
       _user = user,
       _loginResult = loginResult;

  @override
  bool get isInitializing => _isInitializing;

  @override
  bool get isLoading => _isLoading;

  @override
  UserModel? get user => _user;

  @override
  bool get isLoggedIn => _user != null;

  @override
  Future<String?> login(
    String email,
    String password, {
    bool rememberMe = false,
    String langCode = 'en',
  }) async => _loginResult;

  @override
  Future<({String? error, bool isNewUser})> loginWithGoogle({
    bool rememberMe = false,
    String langCode = 'en',
  }) async => (error: null, isNewUser: false);

  @override
  Future<void> logout() async {}

  @override
  Future<void> loadUserFromPrefs() async {}

  @override
  Future<void> completeGoogleSignUp({bool rememberMe = false}) async {}

  @override
  void addLocalAchievement(String achievementId) {}

  @override
  Future<void> handleAppLifecycle(AppLifecycleState state) async {}

  @override
  Future<void> updatePhotoUrl(String photoUrl) async {}

  @override
  Future<String?> deleteAccount(
    String password, {
    String langCode = 'en',
  }) async => null;

  @override
  Future<String?> exportUserDataCsv({String langCode = 'en'}) async => null;

  @override
  Future<List<List<String>>?> exportUserDataRows({
    String langCode = 'en',
  }) async => null;
}
