import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

class LanguageProvider with ChangeNotifier {
  String _currentLang = 'en'; // default

  String get currentLang => _currentLang;

  LanguageProvider() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLang = prefs.getString('appLanguage');
    if (savedLang != null) {
      _currentLang = savedLang;
      notifyListeners();
    }
  }

  Future<void> setLanguage(String lang) async {
    _currentLang = lang;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('appLanguage', lang);
    // Keep FCM language topic in sync so targeted notifications reach
    // the right users.
    await NotificationService().subscribeToLanguageTopic(lang);
  }
}
