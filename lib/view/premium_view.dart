import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_model/settings_view_model.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 다크모드 여부 확인
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 텍스트 기본 색상 (다크면 흰색, 라이트면 검은색)
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Scaffold(
      // [수정] 테마 배경색 따르기
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        // [수정] 앱바 색상 테마 따르기
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: textColor), // 아이콘 색상 자동 조절
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.workspace_premium, size: 80, color: Colors.amber),
            const SizedBox(height: 24),

            Text(
              "プレミアムプラン",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 10),
            Text(
              "すべての機能を開放して、\nより快適にタスクを管理しましょう。",
              textAlign: TextAlign.center,
              style: TextStyle(color: subTextColor, fontSize: 14),
            ),
            const SizedBox(height: 40),

            // 혜택 리스트 (파라미터로 색상 전달)
            _buildBenefitItem(Icons.block, "広告を非表示", "邪魔な広告をすべて削除します", textColor, subTextColor),
            _buildBenefitItem(Icons.push_pin, "ピン留め無制限", "重要なタスクをいくつでも固定できます", textColor, subTextColor),
            _buildBenefitItem(Icons.cloud_sync, "クラウド同期 (予定)", "データを安全にバックアップします", textColor, subTextColor),

            const Spacer(),

            // 구매 버튼
            Consumer<SettingsViewModel>(
              builder: (context, vm, child) {
                return SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor, // 테마 포인트 컬러 사용
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () async {
                      bool success = await vm.buyPremium();
                      if (success && context.mounted) {
                        Navigator.pop(context);
                        // 스낵바는 제거했으므로 생략
                      }
                    },
                    child: const Text(
                      "￥300 / 月 で購入",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // 복원 버튼
            TextButton(
              onPressed: () async {
                final vm = context.read<SettingsViewModel>();
                await vm.restorePurchase();
                if (context.mounted && vm.isPremium) {
                  Navigator.pop(context);
                }
              },
              child: Text("購入を復元する (Restore)", style: TextStyle(color: subTextColor)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // [수정] 텍스트 색상을 인자로 받아서 처리
  Widget _buildBenefitItem(IconData icon, String title, String desc, Color titleColor, Color descColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.indigo.withOpacity(0.1), // 배경은 연하게 유지
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.indigo, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: titleColor),
              ),
              Text(desc, style: TextStyle(color: descColor, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
