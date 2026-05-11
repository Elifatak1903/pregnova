import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleController extends ChangeNotifier {
  static const _localeKey = 'selected_locale_code';

  Locale? _locale;

  Locale? get locale => _locale;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_localeKey);

    if (code == null || code.isEmpty) {
      _locale = null;
    } else {
      _locale = Locale(code);
    }

    notifyListeners();
  }

  Future<void> setLocale(Locale? locale) async {
    if (_locale == locale) return;
    _locale = locale;

    final prefs = await SharedPreferences.getInstance();
    final code = locale?.languageCode;

    if (code == null || code.isEmpty) {
      await prefs.remove(_localeKey);
    } else {
      await prefs.setString(_localeKey, code);
    }

    notifyListeners();
  }

  Future<void> useSystemLocale() {
    return setLocale(null);
  }
}

final localeController = LocaleController();
