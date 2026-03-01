import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../services/localization_service.dart';

/// Helper class for easy access to translations
/// Use with Provider: final t = Translate.of(context);
/// Then access translations like: t.common('loading') or t.auth('login')
class Translate {
  final String _lang;
  final LocalizationService _service = LocalizationService.instance;

  Translate._(this._lang);

  /// Get Translate instance from context
  static Translate of(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(
      context,
      listen: false,
    ).currentLang;
    return Translate._(lang);
  }

  /// Get Translate instance with explicit language (useful for listen: true)
  static Translate withLang(String lang) {
    return Translate._(lang);
  }

  /// Common translations (buttons, labels, etc.)
  String common(String key) => _service.common(key, _lang);

  /// Authentication translations
  String auth(String key) => _service.auth(key, _lang);

  /// Home screen translations
  String home(String key) => _service.home(key, _lang);

  /// Profile screen translations
  String profile(String key) => _service.profile(key, _lang);

  /// Chat screen translations
  String chat(String key) => _service.chat(key, _lang);

  /// Questionnaires translations
  String questionnaires(String key) => _service.questionnaires(key, _lang);

  /// Achievements translations
  String achievements(String key) => _service.achievements(key, _lang);

  /// Validator translations
  String validators(String key) => _service.validators(key, _lang);

  /// Get current language
  String get lang => _lang;

  /// Check if current language is Sinhala
  bool get isSinhala => _lang == 'si';

  /// Check if current language is English
  bool get isEnglish => _lang == 'en';
}

/// Widget extension for easier access to translations
extension TranslateContext on BuildContext {
  /// Quick access to translations
  /// Usage: context.t.common('loading')
  Translate get t => Translate.of(this);

  /// Get current language
  String get currentLang =>
      Provider.of<LanguageProvider>(this, listen: false).currentLang;

  /// Check if current language is Sinhala
  bool get isSinhala => currentLang == 'si';

  /// Check if current language is English
  bool get isEnglish => currentLang == 'en';
}
