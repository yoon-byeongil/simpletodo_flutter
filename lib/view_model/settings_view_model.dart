import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsViewModel extends ChangeNotifier {
  bool _isDarkMode = false;
  bool _isNotificationOn = true;
  bool _isAutoDelete = false;

  bool get isDarkMode => _isDarkMode;
  bool get isNotificationOn => _isNotificationOn;
  bool get isAutoDelete => _isAutoDelete;

  SettingsViewModel() {
    _loadSettings();
  }

  void toggleDarkMode(bool value) {
    _isDarkMode = value;
    _saveSettings();
    notifyListeners();
  }

  void toggleNotification(bool value) {
    _isNotificationOn = value;
    _saveSettings();
    notifyListeners();
  }

  void toggleAutoDelete(bool value) {
    _isAutoDelete = value;
    _saveSettings();
    notifyListeners();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    await prefs.setBool('isNotificationOn', _isNotificationOn);
    await prefs.setBool('isAutoDelete', _isAutoDelete);
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _isNotificationOn = prefs.getBool('isNotificationOn') ?? true;
    _isAutoDelete = prefs.getBool('isAutoDelete') ?? false;
    notifyListeners();
  }

  // 모든 설정을 초기화하는 메서드
  Future<void> clearAllSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _isDarkMode = false;
    _isNotificationOn = true;
    _isAutoDelete = false;
    notifyListeners();
  }
}
