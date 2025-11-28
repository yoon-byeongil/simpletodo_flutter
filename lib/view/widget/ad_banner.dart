import 'package:flutter/material.dart';

class AdBanner extends StatelessWidget {
  const AdBanner({super.key});

  @override
  Widget build(BuildContext context) {
    // 다크모드인지 확인 (색상 결정을 위해)
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 100, // 아까 요청하신 대로 100으로 설정
      width: double.infinity,
      color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("ADVERTISEMENT", style: TextStyle(fontSize: 10, color: isDark ? Colors.grey.shade600 : Colors.grey)),
          const SizedBox(height: 4),
          Text(
            "広告バナー領域 (Large Banner)",
            style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
