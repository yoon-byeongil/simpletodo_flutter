import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class PurchaseService {
  static final PurchaseService _instance = PurchaseService._internal();
  factory PurchaseService() => _instance;
  PurchaseService._internal();

  // [테스트 모드] true면 실제 결제 없이 프리미엄으로 전환됨
  final bool _isTestMode = true;

  // 나중에 RevenueCat에서 발급받은 키를 넣으세요
  final String _apiKeyGoogle = 'goog_placeholder';
  final String _apiKeyApple = 'appl_placeholder';

  bool isPremium = false;

  Future<void> init() async {
    if (_isTestMode) {
      debugPrint("🔧 결제 테스트 모드 ON");
      return;
    }

    await Purchases.setLogLevel(LogLevel.debug);

    PurchasesConfiguration? configuration;
    if (Platform.isAndroid) {
      configuration = PurchasesConfiguration(_apiKeyGoogle);
    } else if (Platform.isIOS) {
      configuration = PurchasesConfiguration(_apiKeyApple);
    }

    if (configuration != null) {
      await Purchases.configure(configuration);
      await checkSubscriptionStatus();
    }
  }

  Future<void> checkSubscriptionStatus() async {
    if (_isTestMode) return;

    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      if (customerInfo.entitlements.all['premium']?.isActive == true) {
        isPremium = true;
      } else {
        isPremium = false;
      }
    } catch (e) {
      isPremium = false;
    }
  }

  // 구매 시도
  Future<bool> purchasePremium() async {
    if (_isTestMode) {
      // [테스트] 무조건 성공 처리
      isPremium = true;
      return true;
    }

    try {
      Offerings offerings = await Purchases.getOfferings();
      if (offerings.current != null && offerings.current!.availablePackages.isNotEmpty) {
        final package = offerings.current!.availablePackages.first;
        CustomerInfo customerInfo = await Purchases.purchasePackage(package);

        if (customerInfo.entitlements.all['premium']?.isActive == true) {
          isPremium = true;
          return true;
        }
      }
    } catch (e) {
      debugPrint("구매 실패: $e");
    }
    return false;
  }

  Future<bool> restorePurchases() async {
    if (_isTestMode) {
      isPremium = true;
      return true;
    }

    try {
      CustomerInfo customerInfo = await Purchases.restorePurchases();
      if (customerInfo.entitlements.all['premium']?.isActive == true) {
        isPremium = true;
        return true;
      }
    } catch (e) {
      debugPrint("복원 실패: $e");
    }
    return false;
  }

  void reset() {
    isPremium = false;
    debugPrint("🔄 구매 상태 초기화됨 (Premium -> Free)");
  }
}
