import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  Locale? _locale;

  Locale? get locale => _locale;

  LocaleProvider() {
    _loadFromPrefs();
  }

  void setLocale(Locale locale) {
    if (!['en', 'ar'].contains(locale.languageCode)) return;

    _locale = locale;
    _saveToPrefs(locale.languageCode);
    notifyListeners();
  }

  void clearLocale() {
    _locale = null;
    _saveToPrefs('');
    notifyListeners();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('language_code') ?? 'en';
    if (languageCode.isNotEmpty) {
      _locale = Locale(languageCode);
      notifyListeners();
    }
  }

  Future<void> _saveToPrefs(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', languageCode);
  }
}
