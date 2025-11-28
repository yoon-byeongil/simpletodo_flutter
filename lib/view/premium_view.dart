import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_model/settings_view_model.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            // 아이콘
            const Icon(Icons.workspace_premium, size: 80, color: Colors.amber),
            const SizedBox(height: 24),

            // 타이틀
            const Text("プレミアムプラン", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text(
              "すべての機能を開放して、\nより快適にタスクを管理しましょう。",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 40),

            // 혜택 리스트
            _buildBenefitItem(Icons.block, "広告を非表示", "邪魔な広告をすべて削除します"),
            _buildBenefitItem(Icons.push_pin, "ピン留め無制限", "重要なタスクをいくつでも固定できます"),
            _buildBenefitItem(Icons.cloud_sync, "クラウド同期 (予定)", "データを安全にバックアップします"),

            const Spacer(),

            // 구매 버튼
            Consumer<SettingsViewModel>(
              builder: (context, vm, child) {
                return SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () async {
                      bool success = await vm.buyPremium();
                      if (success && context.mounted) {
                        Navigator.pop(context); // 성공하면 창 닫기
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("プレミアム会員になりました！")));
                      }
                    },
                    child: const Text(
                      "￥300 / 月 で購入", // 가격은 예시
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("購入状況を確認しました")));
                  if (vm.isPremium) Navigator.pop(context);
                }
              },
              child: const Text("購入を復元する (Restore)", style: TextStyle(color: Colors.grey)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.indigo.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: Colors.indigo, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
