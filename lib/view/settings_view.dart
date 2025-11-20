import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_model/settings_view_model.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("설정")),
      body: Consumer<SettingsViewModel>(
        builder: (context, vm, child) {
          return Column(
            children: [
              SwitchListTile(
                title: const Text("다크 모드"),
                value: vm.isDarkMode,
                onChanged: (val) => vm.toggleDarkMode(val),
              ),
              SwitchListTile(
                title: const Text("알림 켜기"),
                subtitle: const Text("일정 시간에 알림을 받습니다"),
                value: vm.isNotificationOn,
                onChanged: (val) => vm.toggleNotification(val),
              ),
              SwitchListTile(
                title: const Text("완료 시 자동 삭제"),
                subtitle: const Text("체크하면 목록에서 바로 사라집니다"),
                value: vm.isAutoDelete,
                onChanged: (val) => vm.toggleAutoDelete(val),
              ),
            ],
          );
        },
      ),
    );
  }
}