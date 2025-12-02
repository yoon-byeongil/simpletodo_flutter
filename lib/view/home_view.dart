import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

// [상수 및 뷰모델, 커스텀 위젯 임포트]
import '../const/app_colors.dart';
import '../const/app_strings.dart';
import '../view_model/todo_view_model.dart';
import '../view_model/settings_view_model.dart';
import 'settings_view.dart';
import 'widget/todo_bottom_sheet.dart';
import 'widget/ad_banner.dart';
import 'premium_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _titleController = TextEditingController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // [기능] 1분마다 화면을 갱신하여 '마감 기한 지남(Overdue)' 상태를 실시간 반영
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) setState(() {});
    });

    // [기능] 화면이 빌드된 직후 안드로이드 알람 권한 체크 실행
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndroidPermission();
    });
  }

  // [로직] 안드로이드 정확한 알람 권한 확인 및 유도 팝업
  Future<void> _checkAndroidPermission() async {
    if (Theme.of(context).platform == TargetPlatform.android) {
      // ViewModel에 권한 상태 확인 요청
      final isDenied = await context.read<TodoViewModel>().checkPermissionStatus();
      if (isDenied && mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text(AppStrings.notificationSetting),
            content: const Text(AppStrings.msgNotiPermission),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text(AppStrings.later)),
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  // ViewModel을 통해 권한 요청 실행
                  await context.read<TodoViewModel>().requestPermission();
                },
                child: const Text(AppStrings.setting, style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel(); // 타이머 종료 (메모리 누수 방지)
    _titleController.dispose();
    super.dispose();
  }

  // [UI] 할 일 추가 바텀 시트 열기
  void _onAddPressed() {
    if (_titleController.text.isEmpty) return;

    // 현재 시간을 5분 단위로 스냅(보정)하여 초기값 설정
    DateTime initialTime = context.read<TodoViewModel>().normalizeToFiveMinutes(DateTime.now());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        // 분리된 위젯(TodoBottomSheet) 사용
        return TodoBottomSheet(
          initialTitle: _titleController.text,
          initialDue: initialTime,
          initialReminder: null,
          onSaved: (String title, DateTime due, DateTime? reminder) {
            final isGlobalOn = context.read<SettingsViewModel>().isNotificationOn;
            // ViewModel에 추가 요청
            context.read<TodoViewModel>().addTodo(title, due, reminder, isGlobalOn);
            _titleController.clear();
            FocusScope.of(context).unfocus();
          },
        );
      },
    );
  }

  // [UI] 할 일 수정 바텀 시트 열기
  void _onEditPressed(int index, String currentTitle, DateTime currentDue, DateTime? currentReminder) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return TodoBottomSheet(
          initialTitle: currentTitle,
          initialDue: currentDue,
          initialReminder: currentReminder,
          onSaved: (String title, DateTime due, DateTime? reminder) {
            final isGlobalOn = context.read<SettingsViewModel>().isNotificationOn;
            // ViewModel에 수정 요청
            context.read<TodoViewModel>().editTodo(index, title, due, reminder, isGlobalOn);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.tasksTitle, style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          // 설정 화면 이동 버튼
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())),
          ),
        ],
      ),
      // [상태 관리] Todo와 Settings 뷰모델을 동시에 구독
      body: Consumer2<TodoViewModel, SettingsViewModel>(
        builder: (context, todoVM, settingsVM, child) {
          return Column(
            children: [
              // 1. 상단 간편 입력창 영역
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          hintText: AppStrings.hintText,
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF5F5F7),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton.filled(
                      onPressed: _onAddPressed,
                      style: IconButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        backgroundColor: Theme.of(context).primaryColor,
                      ),
                      icon: const Icon(Icons.arrow_upward, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // 2. 할 일 리스트 영역
              Expanded(
                child: todoVM.todos.isEmpty
                    ? Center(
                        // 할 일이 없을 때 표시
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.task_alt, size: 60, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            const Text(AppStrings.noTasks, style: TextStyle(color: Colors.grey, fontSize: 16)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: todoVM.todos.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final todo = todoVM.todos[index];
                          // [로직] 마감 시간이 지났고 완료되지 않았는지 확인
                          final isOverdue = todo.dueDateTime.isBefore(DateTime.now()) && !todo.isDone;

                          return Slidable(
                            key: ValueKey(todo.id),
                            // [왼쪽 슬라이드] 핀 고정 (BM 적용: 프리미엄 체크)
                            startActionPane: ActionPane(
                              motion: const ScrollMotion(),
                              children: [
                                SlidableAction(
                                  onPressed: (context) {
                                    final isPremium = context.read<SettingsViewModel>().isPremium;
                                    final navigator = Navigator.of(context);

                                    // ViewModel에 핀 토글 요청 (성공 여부 반환)
                                    bool success = todoVM.togglePin(index, isPremium);

                                    if (!success) {
                                      // [BM] 핀 개수 제한에 걸리면 결제 유도 팝업 표시
                                      showCupertinoDialog(
                                        context: context,
                                        builder: (ctx) => CupertinoAlertDialog(
                                          title: const Text(AppStrings.msgPinLimitTitle),
                                          content: const Text(AppStrings.msgPinLimit),
                                          actions: [
                                            // 교체 (기존 핀 해제 후 설정)
                                            CupertinoDialogAction(
                                              child: const Text(AppStrings.msgReplace),
                                              onPressed: () {
                                                Navigator.pop(ctx);
                                                todoVM.togglePin(index, settingsVM.isPremium, forceReplace: true);
                                              },
                                            ),
                                            // 상세 보기 (프리미엄 화면 이동)
                                            CupertinoDialogAction(
                                              isDefaultAction: true,
                                              child: const Text(AppStrings.msgDetail),
                                              onPressed: () {
                                                Navigator.pop(ctx);
                                                navigator.push(MaterialPageRoute(builder: (context) => const PremiumScreen()));
                                              },
                                            ),
                                            // 취소
                                            CupertinoDialogAction(isDestructiveAction: true, child: const Text(AppStrings.cancel), onPressed: () => Navigator.pop(ctx)),
                                          ],
                                        ),
                                      );
                                    }
                                  },
                                  backgroundColor: AppColors.pin,
                                  foregroundColor: Colors.white,
                                  icon: todo.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                                  label: todo.isPinned ? AppStrings.unpin : AppStrings.pin,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ],
                            ),
                            // [오른쪽 슬라이드] 수정 및 삭제
                            endActionPane: ActionPane(
                              motion: const ScrollMotion(),
                              children: [
                                SlidableAction(
                                  onPressed: (context) => _onEditPressed(index, todo.title, todo.dueDateTime, todo.reminderTime),
                                  backgroundColor: AppColors.edit,
                                  foregroundColor: Colors.white,
                                  icon: Icons.edit,
                                  label: AppStrings.edit,
                                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                                ),
                                SlidableAction(
                                  onPressed: (context) => todoVM.deleteTodo(index),
                                  backgroundColor: AppColors.delete,
                                  foregroundColor: Colors.white,
                                  icon: Icons.delete,
                                  label: AppStrings.delete,
                                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                                ),
                              ],
                            ),
                            // [카드 UI] 할 일 정보 표시
                            child: Card(
                              margin: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                // 핀 고정 시 테두리로 강조
                                side: todo.isPinned ? const BorderSide(color: Colors.grey, width: 2) : BorderSide.none,
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                leading: Transform.scale(
                                  scale: 1.1,
                                  child: Checkbox(
                                    shape: const CircleBorder(),
                                    activeColor: Theme.of(context).primaryColor,
                                    value: todo.isDone,
                                    onChanged: (_) => todoVM.toggleDone(index, settingsVM.isAutoDelete),
                                  ),
                                ),
                                title: Text(
                                  todo.title,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    decoration: todo.isDone ? TextDecoration.lineThrough : null,
                                    color: todo.isDone ? Colors.grey : Theme.of(context).textTheme.bodyLarge?.color,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        // 마감일 표시 (지났으면 빨간색)
                                        Icon(Icons.calendar_today, size: 14, color: isOverdue ? Colors.red : Colors.grey.shade600),
                                        const SizedBox(width: 4),
                                        Text(
                                          DateFormat('yyyy/MM/dd HH:mm').format(todo.dueDateTime),
                                          style: TextStyle(color: isOverdue ? Colors.red : Colors.grey.shade600, fontSize: 13, fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal),
                                        ),
                                        if (isOverdue)
                                          const Text(
                                            AppStrings.overdue,
                                            style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                      ],
                                    ),
                                    // 알림이 설정된 경우 표시
                                    if (todo.reminderTime != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.notifications_active, size: 14, color: AppColors.notification),
                                            const SizedBox(width: 4),
                                            Text(
                                              DateFormat('MM/dd HH:mm').format(todo.reminderTime!),
                                              style: const TextStyle(color: AppColors.notification, fontSize: 13, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: todo.isPinned ? Icon(Icons.push_pin, color: AppColors.pin, size: 20) : null,
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // 3. [BM] 하단 광고 배너 (프리미엄 미가입 시에만 표시)
              if (!settingsVM.isPremium) const AdBanner(),
            ],
          );
        },
      ),
    );
  }
}
