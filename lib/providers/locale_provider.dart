import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  static const String _localeKey = 'selected_locale';

  Locale? _locale;
  Locale? get locale => _locale;

  // 지원하는 언어 목록
  static const supportedLocales = [
    Locale('ko'),
    Locale('en'),
    Locale('ja'),
  ];

  // 언어 이름 (해당 언어로 표시)
  static String getLanguageName(String code) {
    switch (code) {
      case 'ko':
        return '한국어';
      case 'en':
        return 'English';
      case 'ja':
        return '日本語';
      default:
        return code;
    }
  }

  // 언어 플래그 이모지
  static String getLanguageFlag(String code) {
    switch (code) {
      case 'ko':
        return '🇰🇷';
      case 'en':
        return '🇺🇸';
      case 'ja':
        return '🇯🇵';
      default:
        return '🌐';
    }
  }

  LocaleProvider() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final localeCode = prefs.getString(_localeKey);

    if (localeCode != null) {
      _locale = Locale(localeCode);
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (!supportedLocales.contains(locale)) return;

    _locale = locale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
  }

  Future<void> clearLocale() async {
    _locale = null;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_localeKey);
  }
}
