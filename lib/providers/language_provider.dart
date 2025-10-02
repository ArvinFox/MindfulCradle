import 'package:flutter/material.dart';

class LanguageProvider with ChangeNotifier {
  String _currentLang = 'en'; // default english

  String get currentLang => _currentLang;

  void setLanguage(String langCode) {
    if (langCode != _currentLang) {
      _currentLang = langCode;
      notifyListeners();
    }
  }
}
