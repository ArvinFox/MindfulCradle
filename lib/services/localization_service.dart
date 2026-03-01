import 'dart:convert';
import 'package:flutter/services.dart';

/// Centralized localization service for loading and accessing translations
/// Loads all language JSON files from the languages/ directory
class LocalizationService {
  static LocalizationService? _instance;
  static LocalizationService get instance {
    _instance ??= LocalizationService._();
    return _instance!;
  }

  LocalizationService._();

  // Loaded translations
  Map<String, dynamic> _common = {};
  Map<String, dynamic> _auth = {};
  Map<String, dynamic> _home = {};
  Map<String, dynamic> _profile = {};
  Map<String, dynamic> _chat = {};
  Map<String, dynamic> _questionnaires = {};
  Map<String, dynamic> _achievements = {};
  Map<String, dynamic> _validators = {};

  bool _isLoaded = false;

  /// Load all translation files
  Future<void> loadTranslations() async {
    if (_isLoaded) return;

    try {
      // Load all JSON files in parallel
      final results = await Future.wait([
        rootBundle.loadString('languages/common.json'),
        rootBundle.loadString('languages/auth.json'),
        rootBundle.loadString('languages/home.json'),
        rootBundle.loadString('languages/profile.json'),
        rootBundle.loadString('languages/chat.json'),
        rootBundle.loadString('languages/questionnaires.json'),
        rootBundle.loadString('languages/achievements.json'),
        rootBundle.loadString('languages/validators.json'),
      ]);

      _common = json.decode(results[0]);
      _auth = json.decode(results[1]);
      _home = json.decode(results[2]);
      _profile = json.decode(results[3]);
      _chat = json.decode(results[4]);
      _questionnaires = json.decode(results[5]);
      _achievements = json.decode(results[6]);
      _validators = json.decode(results[7]);

      _isLoaded = true;
    } catch (e) {
      print('Error loading translations: $e');
      rethrow;
    }
  }

  /// Get translation from common translations
  String common(String key, String lang) {
    return _getText(_common, key, lang);
  }

  /// Get translation from auth module
  String auth(String key, String lang) {
    return _getText(_auth, key, lang);
  }

  /// Get translation from home module
  String home(String key, String lang) {
    return _getText(_home, key, lang);
  }

  /// Get translation from profile module
  String profile(String key, String lang) {
    return _getText(_profile, key, lang);
  }

  /// Get translation from chat module
  String chat(String key, String lang) {
    return _getText(_chat, key, lang);
  }

  /// Get translation from questionnaires module
  String questionnaires(String key, String lang) {
    return _getText(_questionnaires, key, lang);
  }

  /// Get translation from achievements module
  String achievements(String key, String lang) {
    return _getText(_achievements, key, lang);
  }

  /// Get translation from validators module
  String validators(String key, String lang) {
    return _getText(_validators, key, lang);
  }

  /// Internal method to get text from a translation map
  String _getText(Map<String, dynamic> translations, String key, String lang) {
    final langData = translations[lang] as Map<String, dynamic>?;
    if (langData == null) return key;
    return langData[key]?.toString() ?? key;
  }

  /// Check if translations are loaded
  bool get isLoaded => _isLoaded;

  /// Reset the service (useful for testing)
  void reset() {
    _isLoaded = false;
    _common = {};
    _auth = {};
    _home = {};
    _profile = {};
    _chat = {};
    _questionnaires = {};
    _achievements = {};
    _validators = {};
  }
}

/// Extension on String for easier language selection
extension LocalizedString on String {
  /// Get the translation for this key in the specified language
  /// Returns the key itself if not found
  String tr(String module, String lang) {
    final service = LocalizationService.instance;

    switch (module.toLowerCase()) {
      case 'common':
        return service.common(this, lang);
      case 'auth':
        return service.auth(this, lang);
      case 'home':
        return service.home(this, lang);
      case 'profile':
        return service.profile(this, lang);
      case 'chat':
        return service.chat(this, lang);
      case 'questionnaires':
        return service.questionnaires(this, lang);
      case 'achievements':
        return service.achievements(this, lang);
      case 'validators':
        return service.validators(this, lang);
      default:
        return this;
    }
  }
}
