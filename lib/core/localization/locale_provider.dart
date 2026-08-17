import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import './app_localizations.dart';

class LocaleProvider extends ChangeNotifier {
  AppLanguage _language = AppLanguage.english;
  bool _isDarkMode = false;

  AppLanguage get language => _language;
  bool get isDarkMode => _isDarkMode;
  bool get isRTL =>
      _language == AppLanguage.arabic || _language == AppLanguage.kurdish;

  TextDirection get textDirection =>
      isRTL ? TextDirection.rtl : TextDirection.ltr;

  LocaleProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final langIndex = prefs.getInt('language_index');
      if (langIndex != null) {
        _language = AppLanguage.values[
            langIndex.clamp(0, AppLanguage.values.length - 1)];
      } else {
        final preAuthLang = prefs.getString('pre_auth_language');
        _language = _languageFromCode(preAuthLang);
      }
      _isDarkMode = prefs.getBool('dark_mode') ?? false;
      notifyListeners();
    } catch (_) {}
  }

  AppLanguage _languageFromCode(String? code) {
    switch (code) {
      case 'ar':
        return AppLanguage.arabic;
      case 'ku':
        return AppLanguage.kurdish;
      default:
        return AppLanguage.english;
    }
  }

  Future<void> setLanguage(AppLanguage lang) async {
    _language = lang;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('language_index', lang.index);
    } catch (_) {}
  }

  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('dark_mode', value);
    } catch (_) {}
  }

  Future<void> toggleDarkMode() async {
    await setDarkMode(!_isDarkMode);
  }
}
