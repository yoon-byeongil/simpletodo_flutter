import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_model/settings_view_model.dart';
import '../view_model/todo_view_model.dart'; // [필수] TodoViewModel 접근을 위해 import

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 설정을 변경할 때 TodoViewModel도 같이 조작해야 하므로 둘 다 가져옵니다.
    return Scaffold(
      appBar: AppBar(title: const Text("설정")),
      body: Consumer2<SettingsViewModel, TodoViewModel>(
        builder: (context, settingsVM, todoVM, child) {
          return Column(
            children: [
              SwitchListTile(title: const Text("다크 모드"), value: settingsVM.isDarkMode, onChanged: (val) => settingsVM.toggleDarkMode(val)),
              SwitchListTile(
                title: const Text("알림 켜기"),
                subtitle: const Text("일정 시간에 알림을 받습니다"),
                value: settingsVM.isNotificationOn,
                onChanged: (val) {
                  // 1. 설정값 변경 (저장)
                  settingsVM.toggleNotification(val);

                  // 2. 실제 알림 시스템 조작
                  if (val) {
                    // 켜짐 -> 기존 알림들 복구 (재예약)
                    todoVM.restoreAllReminders();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("모든 알림이 활성화되었습니다."), duration: Duration(seconds: 1)));
                  } else {
                    // 꺼짐 -> 모든 알림 취소
                    todoVM.cancelAllReminders();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("모든 알림이 차단되었습니다."), duration: Duration(seconds: 1)));
                  }
                },
              ),
              SwitchListTile(title: const Text("완료 시 자동 삭제"), subtitle: const Text("체크하면 목록에서 바로 사라집니다"), value: settingsVM.isAutoDelete, onChanged: (val) => settingsVM.toggleAutoDelete(val)),
            ],
          );
        },
      ),
    );
  }
}
