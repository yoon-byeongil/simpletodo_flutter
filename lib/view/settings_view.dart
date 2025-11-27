import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../view_model/settings_view_model.dart';
import '../view_model/todo_view_model.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer2<SettingsViewModel, TodoViewModel>(
      builder: (context, settingsVM, todoVM, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            title: Text(
              "設定",
              style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).appBarTheme.foregroundColor),
            ),
            iconTheme: IconThemeData(color: Theme.of(context).appBarTheme.foregroundColor),
          ),

          // [광고] 하단 배너 (프리미엄이 아닐 때만 표시)
          bottomNavigationBar: !settingsVM.isPremium
              ? Container(
                  height: 60,
                  width: double.infinity,
                  color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("ADVERTISEMENT", style: TextStyle(fontSize: 10, color: isDark ? Colors.grey.shade600 : Colors.grey)),
                      Text(
                        "広告バナー領域 (Google AdMob)",
                        style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
              : null, // 프리미엄이면 숨김

          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // [BM] 상단 프리미엄 구매 유도 배너 (프리미엄 아닐 때만 표시)
              if (!settingsVM.isPremium) ...[
                Card(
                  color: Colors.indigo,
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: const Icon(Icons.workspace_premium, color: Colors.amber, size: 32),
                    title: const Text(
                      "プレミアムにアップグレード",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text("無制限ピン留め・広告なし", style: TextStyle(color: Colors.white70, fontSize: 12)),
                    trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                    onTap: () async {
                      // 결제 시도 (테스트 모드이므로 바로 성공)
                      bool success = await settingsVM.buyPremium();
                      if (success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("ありがとうございます！プレミアムになりました。")));
                      }
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // 1. 일반 설정 섹션
              const Text(
                "一般 (General)",
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              Container(
                decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    // 다크 모드
                    SwitchListTile(title: const Text("ダークモード"), secondary: const Icon(Icons.dark_mode_outlined), value: settingsVM.isDarkMode, onChanged: (val) => settingsVM.toggleDarkMode(val)),
                    Divider(height: 1, indent: 50, color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),

                    // 알림 설정
                    SwitchListTile(
                      title: const Text("通知を許可"),
                      subtitle: Text("締め切り時間に通知を受け取ります", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
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

                    // 자동 삭제 설정
                    SwitchListTile(
                      title: const Text("完了時に自動削除"),
                      subtitle: Text("チェックするとリストから削除されます", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                      secondary: const Icon(Icons.auto_delete_outlined),
                      value: settingsVM.isAutoDelete,
                      onChanged: (val) => settingsVM.toggleAutoDelete(val),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // 2. 데이터 관리 섹션
              const Text(
                "データ管理 (Data)",
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              Container(
                decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    // 기한 지난 일정 삭제
                    ListTile(
                      leading: const Icon(Icons.cleaning_services_outlined, color: Colors.orange),
                      title: const Text("期限切れのタスクを削除", style: TextStyle(color: Colors.orange)),
                      subtitle: const Text("過去のタスクを一括削除します"),
                      onTap: () {
                        showCupertinoDialog(
                          context: context,
                          builder: (ctx) => CupertinoAlertDialog(
                            title: const Text("整理しますか？"),
                            content: const Text("締め切りが過ぎたタスクを全て削除します。"),
                            actions: [
                              CupertinoDialogAction(child: const Text("キャンセル"), onPressed: () => Navigator.pop(ctx)),
                              CupertinoDialogAction(
                                isDestructiveAction: true,
                                child: const Text("削除"),
                                onPressed: () {
                                  todoVM.deleteOverdueTodos();
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("期限切れのタスクを削除しました")));
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    Divider(height: 1, indent: 50, color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),

                    // 데이터 초기화 (결제 상태도 초기화됨)
                    ListTile(
                      leading: const Icon(Icons.delete_forever, color: Colors.red),
                      title: const Text("データを初期化", style: TextStyle(color: Colors.red)),
                      subtitle: const Text("全てのタスクと設定が削除されます"),
                      onTap: () {
                        showCupertinoDialog(
                          context: context,
                          builder: (ctx) => CupertinoAlertDialog(
                            title: const Text("初期化しますか？"),
                            content: const Text("この操作は取り消せません。\n(プレミアム状態もリセットされます)"),
                            actions: [
                              CupertinoDialogAction(child: const Text("キャンセル"), onPressed: () => Navigator.pop(ctx)),
                              CupertinoDialogAction(
                                isDestructiveAction: true,
                                onPressed: () async {
                                  // 할 일 목록 초기화
                                  todoVM.clearAllTodos();

                                  if (context.mounted) {
                                    // 설정 및 결제 상태 초기화
                                    await context.read<SettingsViewModel>().clearAllSettings();

                                    Navigator.pop(ctx);
                                    Navigator.pop(context); // 홈으로 이동
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
                    Divider(height: 1, indent: 50, color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),

                    // [BM] 구매 복원 (애플 필수)
                    ListTile(
                      leading: const Icon(Icons.restore, color: Colors.grey),
                      title: const Text("購入を復元 (Restore)"),
                      onTap: () async {
                        await settingsVM.restorePurchase();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("購入状況を確認しました。")));
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
