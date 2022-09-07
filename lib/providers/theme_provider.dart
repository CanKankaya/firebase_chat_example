import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

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

class ThemePreferences {
  static const prefKey = "pref_key";

  setTheme(bool value) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setBool(prefKey, value);
  }

  getTheme() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return sharedPreferences.getBool(prefKey) ?? false;
  }
}
