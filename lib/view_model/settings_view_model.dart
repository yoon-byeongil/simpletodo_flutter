import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../service/purchase_service.dart';

class SettingsViewModel extends ChangeNotifier {
  bool _isDarkMode = false;
  bool _isNotificationOn = true;
  bool _isAutoDelete = false;

  final PurchaseService _purchaseService = PurchaseService();

  bool get isDarkMode => _isDarkMode;
  bool get isNotificationOn => _isNotificationOn;
  bool get isAutoDelete => _isAutoDelete;

  // 프리미엄 여부
  bool get isPremium => _purchaseService.isPremium;

  SettingsViewModel() {
    _loadSettings();
    _initPurchase();
  }

  Future<void> _initPurchase() async {
    await _purchaseService.init();
    notifyListeners();
  }

  Future<bool> buyPremium() async {
    bool success = await _purchaseService.purchasePremium();
    if (success) {
      notifyListeners();
    }
    return success;
  }

  Future<void> restorePurchase() async {
    await _purchaseService.restorePurchases();
    notifyListeners();
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

  // [수정] 데이터 초기화 시 프리미엄 상태도 초기화
  Future<void> clearAllSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    _isDarkMode = false;
    _isNotificationOn = true;
    _isAutoDelete = false;

    // 서비스 상태 리셋
    _purchaseService.reset();

    notifyListeners();
  }
}
