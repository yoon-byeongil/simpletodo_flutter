import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../service/purchase_service.dart';

// [역할] 앱의 전반적인 설정(다크모드, 알림 여부)과 프리미엄 상태를 관리하는 ViewModel
class SettingsViewModel extends ChangeNotifier {
  // --- 상태 변수 (State Variables) ---
  bool _isDarkMode = false; // 다크모드 여부
  bool _isNotificationOn = true; // 알림 켜짐/꺼짐
  bool _isAutoDelete = false; // 완료 시 자동 삭제 여부

  // 결제 기능을 담당하는 외부 서비스 객체
  final PurchaseService _purchaseService = PurchaseService();

  // --- Getter (View에서 읽기 전용으로 접근) ---
  bool get isDarkMode => _isDarkMode;
  bool get isNotificationOn => _isNotificationOn;
  bool get isAutoDelete => _isAutoDelete;

  // [중요] 프리미엄 여부는 내부에 저장하지 않고 Service에서 실시간으로 가져옴
  // (결제 정보는 보안상 Service나 서버가 관리하는 것이 원칙)
  bool get isPremium => _purchaseService.isPremium;

  // 생성자: 앱이 켜질 때 저장된 설정을 불러오고, 결제 시스템을 초기화함
  SettingsViewModel() {
    _loadSettings();
    _initPurchase();
  }

  // ------------------------------------------------------------------
  // [결제 관련 로직] UI와 PurchaseService를 연결
  // ------------------------------------------------------------------

  // 결제 서비스 초기화 (RevenueCat 연결)
  Future<void> _initPurchase() async {
    await _purchaseService.init();
    notifyListeners(); // 초기화 후 상태 변경 알림
  }

  // 프리미엄 구매 시도
  Future<bool> buyPremium() async {
    // 실제 구매 로직은 Service에 위임
    bool success = await _purchaseService.purchasePremium();
    if (success) {
      notifyListeners(); // 성공 시 UI 갱신 (광고 제거, 배너 숨김)
    }
    return success;
  }

  // 구매 복원 (기기 변경 시)
  Future<void> restorePurchase() async {
    await _purchaseService.restorePurchases();
    notifyListeners(); // 복원된 상태 UI 반영
  }

  // ------------------------------------------------------------------
  // [설정 변경 로직] 값 변경 -> 저장 -> UI 갱신
  // ------------------------------------------------------------------

  void toggleDarkMode(bool value) {
    _isDarkMode = value;
    _saveSettings(); // 변경 즉시 저장소에 기록
    notifyListeners(); // 화면 모드 변경 (Theme 재빌드)
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

  // ------------------------------------------------------------------
  // [데이터 영속화] Shared Preferences (내부 저장소)
  // ------------------------------------------------------------------

  // 설정값을 핸드폰 내부 저장소에 저장 (앱 꺼도 유지되게)
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    await prefs.setBool('isNotificationOn', _isNotificationOn);
    await prefs.setBool('isAutoDelete', _isAutoDelete);
  }

  // 저장된 설정값을 불러오기
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    // 저장된 값이 없으면(??) 기본값(false/true) 사용
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _isNotificationOn = prefs.getBool('isNotificationOn') ?? true;
    _isAutoDelete = prefs.getBool('isAutoDelete') ?? false;
    notifyListeners(); // 불러온 값으로 UI 업데이트
  }

  // [데이터 초기화] '초기화' 버튼을 눌렀을 때 실행
  Future<void> clearAllSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // 1. 내부 저장소 싹 비우기

    // 2. 메모리 상의 변수들도 초기값으로 리셋
    _isDarkMode = false;
    _isNotificationOn = true;
    _isAutoDelete = false;

    // 3. 결제 상태도 무료 버전으로 리셋 (테스트용)
    _purchaseService.reset();

    notifyListeners(); // UI 갱신
  }
}
