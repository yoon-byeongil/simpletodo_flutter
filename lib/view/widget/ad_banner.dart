import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  final String _adUnitId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/6300978111' // 안드로이드 테스트 ID
      : 'ca-app-pub-3940256099942544/2934735716'; // iOS 테스트 ID

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      // ▼▼▼ [수정] 배너 사이즈를 'LargeBanner' (320x100)로 키움 ▼▼▼
      size: AdSize.largeBanner,
      // ▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
          debugPrint('광고 로드 실패: $err');
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoaded && _bannerAd != null) {
      return Container(
        alignment: Alignment.center,
        width: double.infinity,
        height: _bannerAd!.size.height.toDouble(), // 광고 크기(100)에 맞춤
        color: isDark ? Colors.black : Colors.white, // 배경색 깔끔하게 처리
        child: AdWidget(ad: _bannerAd!),
      );
    } else {
      // 로딩 중일 때 보여줄 빈 박스 (크기 미리 확보)
      return Container(
        height: 100, // Large Banner 높이만큼 확보
        width: double.infinity,
        color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("ADVERTISEMENT", style: TextStyle(fontSize: 10, color: isDark ? Colors.grey.shade600 : Colors.grey)),
            const SizedBox(height: 4),
            Text(
              "Loading Ad...",
              style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
            ),
          ],
        ),
      );
    }
  }
}
