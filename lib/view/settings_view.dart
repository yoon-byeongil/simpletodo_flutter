import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../const/app_strings.dart';
import '../const/app_colors.dart';
import '../view_model/settings_view_model.dart';
import '../view_model/todo_view_model.dart';
import 'widget/ad_banner.dart';
import 'premium_view.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showActionDialog(BuildContext context, String title, String content, String actionText, VoidCallback onAction) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          CupertinoDialogAction(child: const Text(AppStrings.cancel), onPressed: () => Navigator.pop(ctx)),
          CupertinoDialogAction(isDestructiveAction: true, onPressed: onAction, child: Text(actionText)),
        ],
      ),
    );
  }

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
              AppStrings.settingsTitle,
              style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).appBarTheme.foregroundColor),
            ),
            iconTheme: IconThemeData(color: Theme.of(context).appBarTheme.foregroundColor),
          ),
          bottomNavigationBar: !settingsVM.isPremium ? const AdBanner() : null,
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (!settingsVM.isPremium) ...[
                Card(
                  color: AppColors.premiumBg,
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: const Icon(Icons.workspace_premium, color: AppColors.premiumIcon, size: 32),
                    title: const Text(
                      AppStrings.premiumUpgrade,
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(AppStrings.premiumDesc, style: TextStyle(color: Colors.white70, fontSize: 12)),
                    trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const PremiumScreen()));
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],

              FutureBuilder<bool>(
                // isBatteryOptimized() 대신 shouldShowBatteryWarning() 사용
                future: settingsVM.shouldShowBatteryWarning(),
                builder: (context, snapshot) {
                  // false 이거나 데이터가 없으면 숨김 (픽셀, 갤럭시는 여기서 숨겨짐)
                  if (!snapshot.hasData || snapshot.data == false) {
                    return const SizedBox.shrink();
                  }

                  // 중국 폰이고 + 최적화가 켜져 있을 때만 보임
                  return Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withOpacity(0.5)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: const Icon(Icons.battery_alert, color: Colors.orange),
                      title: const Text(
                        "通知設定の確認", // 문구 조금 더 부드럽게 변경
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.orange),
                      ),
                      subtitle: const Text("この端末ではバッテリー設定の変更が必要な場合があります", style: TextStyle(fontSize: 12)),
                      onTap: () async {
                        await settingsVM.requestBatteryOptimizationOff();
                      },
                    ),
                  );
                },
              ),

              // ▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲
              Text(
                AppStrings.generalSection,
                style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              Container(
                decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text(AppStrings.darkMode),
                      secondary: const Icon(Icons.dark_mode_outlined),
                      value: settingsVM.isDarkMode,
                      onChanged: (val) => settingsVM.toggleDarkMode(val),
                    ),
                    Divider(height: 1, indent: 50, color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                    SwitchListTile(
                      title: const Text(AppStrings.allowNotification),
                      subtitle: Text(AppStrings.allowNotificationDesc, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      secondary: const Icon(Icons.notifications_outlined),
                      value: settingsVM.isNotificationOn,
                      onChanged: (val) {
                        settingsVM.toggleNotification(val);
                        if (val) {
                          todoVM.restoreAllReminders();
                        } else {
                          todoVM.cancelAllReminders();
                        }
                      },
                    ),
                    Divider(height: 1, indent: 50, color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                    SwitchListTile(
                      title: const Text(AppStrings.autoDelete),
                      subtitle: Text(AppStrings.autoDeleteDesc, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      secondary: const Icon(Icons.auto_delete_outlined),
                      value: settingsVM.isAutoDelete,
                      onChanged: (val) => settingsVM.toggleAutoDelete(val),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
              Text(
                AppStrings.dataSection,
                style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              Container(
                decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.cleaning_services_outlined, color: Colors.orange),
                      title: const Text(AppStrings.deleteOverdue, style: TextStyle(color: Colors.orange)),
                      subtitle: const Text(AppStrings.deleteOverdueDesc),
                      onTap: () => _showActionDialog(context, AppStrings.msgCleanConfirmTitle, AppStrings.msgCleanConfirm, AppStrings.delete, () {
                        todoVM.deleteOverdueTodos();
                        Navigator.pop(context);
                      }),
                    ),
                    Divider(height: 1, indent: 50, color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),

                    // [수정] 비동기 로직 안전장치 추가
                    ListTile(
                      leading: const Icon(Icons.delete_forever, color: Colors.red),
                      title: const Text(AppStrings.clearData, style: TextStyle(color: Colors.red)),
                      subtitle: const Text(AppStrings.clearDataDesc),
                      onTap: () => _showActionDialog(context, AppStrings.msgResetConfirmTitle, AppStrings.msgResetConfirm, AppStrings.confirm, () async {
                        // 1. 할 일 초기화
                        todoVM.clearAllTodos();

                        // 2. 화면이 살아있는지 체크 (중요!)
                        if (!context.mounted) return;

                        // 3. 설정 초기화 (비동기)
                        await context.read<SettingsViewModel>().clearAllSettings();

                        // 4. 다시 화면 살아있는지 체크
                        if (!context.mounted) return;

                        // 5. 화면 이동
                        Navigator.pop(context); // 다이얼로그 닫기
                        Navigator.pop(context); // 설정 화면 닫기 (홈으로)
                      }),
                    ),
                    Divider(height: 1, indent: 50, color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),

                    // [수정] 구매 복원 안전장치 추가
                    ListTile(
                      leading: const Icon(Icons.restore, color: Colors.grey),
                      title: const Text(AppStrings.restorePurchase),
                      onTap: () async {
                        await settingsVM.restorePurchase();

                        // 화면이 살아있을 때만 스낵바 표시
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("購入状況を確認しました")));
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
