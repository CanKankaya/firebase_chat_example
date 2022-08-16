import 'package:flutter/material.dart';

import 'package:firebase_chat_example/providers/theme_preference.dart';

class ThemeModel extends ChangeNotifier {
  bool _isDark = false;
  final ThemePreferences _preferences = ThemePreferences();
  bool get isDark => _isDark;

  ThemeModel() {
    _isDark = false;
    getPreferences();
  }
  set isDark(bool value) {
    _isDark = value;
    _preferences.setTheme(value);
    notifyListeners();
  }

  getPreferences() async {
    _isDark = await _preferences.getTheme();
    notifyListeners();
  }
}
