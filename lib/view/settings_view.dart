import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../view_model/settings_view_model.dart';
import '../view_model/todo_view_model.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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

              Container(
                decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    SwitchListTile(title: const Text("ダークモード"), secondary: const Icon(Icons.dark_mode_outlined), value: settingsVM.isDarkMode, onChanged: (val) => settingsVM.toggleDarkMode(val)),
                    Divider(height: 1, indent: 50, color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),

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
              const Text(
                "データ管理 (Data)",
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              Container(
                decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
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
                    ListTile(
                      leading: const Icon(Icons.delete_forever, color: Colors.red),
                      title: const Text("データを初期化", style: TextStyle(color: Colors.red)),
                      subtitle: const Text("全てのタスクと設定が削除されます"),
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
                                  todoVM.clearAllTodos();
                                  if (context.mounted) {
                                    await context.read<SettingsViewModel>().clearAllSettings();
                                    Navigator.pop(ctx);
                                    Navigator.pop(context);
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
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
