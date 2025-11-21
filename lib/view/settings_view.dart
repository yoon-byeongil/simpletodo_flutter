import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // 아이폰 스타일 다이얼로그용
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../view_model/settings_view_model.dart';
import '../view_model/todo_view_model.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 현재 테마가 다크모드인지 확인 (색상 미세 조정을 위해)
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // [수정] 배경색을 테마에 따르도록 변경 (main.dart에서 설정한 색상 자동 적용)
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        // [수정] 앱바 색상도 테마 적용
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: Text(
          "設定", // 설정
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).appBarTheme.foregroundColor, // 글자색 테마 적용
          ),
        ),
        iconTheme: IconThemeData(
          color: Theme.of(context).appBarTheme.foregroundColor, // 뒤로가기 버튼 색상
        ),
      ),
      body: Consumer2<SettingsViewModel, TodoViewModel>(
        builder: (context, settingsVM, todoVM, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                "一般 (General)",
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // 설정 항목 카드
              Container(
                decoration: BoxDecoration(
                  // [수정] 카드 배경색을 테마에 맞게 변경 (다크모드면 어두운 회색, 아니면 흰색)
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text("ダークモード"), // 다크모드
                      secondary: const Icon(Icons.dark_mode_outlined),
                      value: settingsVM.isDarkMode,
                      onChanged: (val) => settingsVM.toggleDarkMode(val),
                    ),
                    // [수정] 구분선 색상도 너무 튀지 않게 조정
                    Divider(height: 1, indent: 50, color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),

                    SwitchListTile(
                      title: const Text("通知を許可"), // 알림 허용
                      subtitle: Text(
                        "締め切り時間に通知を受け取ります", // 마감 시간에 알림을 받습니다
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      ),
                      secondary: const Icon(Icons.notifications_outlined),
                      value: settingsVM.isNotificationOn,
                      onChanged: (val) {
                        settingsVM.toggleNotification(val);
                        if (val) {
                          todoVM.restoreAllReminders();
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("通知をオンにしました"), duration: Duration(seconds: 1)));
                        } else {
                          todoVM.cancelAllReminders();
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("通知をオフにしました"), duration: Duration(seconds: 1)));
                        }
                      },
                    ),
                    Divider(height: 1, indent: 50, color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),

                    SwitchListTile(
                      title: const Text("完了時に自動削除"), // 완료 시 자동 삭제
                      subtitle: Text(
                        "チェックするとリストから削除されます", // 체크하면 리스트에서 삭제됩니다
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      ),
                      secondary: const Icon(Icons.auto_delete_outlined),
                      value: settingsVM.isAutoDelete,
                      onChanged: (val) => settingsVM.toggleAutoDelete(val),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
              const Text(
                "データ管理 (Data)",
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              Container(
                decoration: BoxDecoration(
                  // [수정] 카드 배경색 테마 적용
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text("データを初期化", style: TextStyle(color: Colors.red)), // 데이터 초기화
                  subtitle: const Text("全てのタスクと設定が削除されます"), // 모든 태스크와 설정이 삭제됩니다
                  onTap: () {
                    showCupertinoDialog(
                      context: context,
                      builder: (ctx) => CupertinoAlertDialog(
                        title: const Text("初期化しますか？"),
                        content: const Text("この操作は取り消せません。"),
                        actions: [
                          CupertinoDialogAction(child: const Text("キャンセル"), onPressed: () => Navigator.pop(ctx)),
                          CupertinoDialogAction(
                            isDestructiveAction: true,
                            onPressed: () async {
                              // [기능] 데이터 초기화 로직
                              todoVM.clearAllTodos();
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.clear();

                              if (context.mounted) {
                                Navigator.pop(ctx); // 다이얼로그 닫기
                                Navigator.pop(context); // 설정화면 닫기
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("初期化しました")));
                              }
                            },
                            child: const Text("初期化"),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
