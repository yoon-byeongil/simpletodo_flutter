import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:permission_handler/permission_handler.dart';

import '../view_model/todo_view_model.dart';
import '../view_model/settings_view_model.dart';
import 'settings_view.dart';
import 'todo_bottom_sheet.dart';

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
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndroidPermission();
    });
  }

  Future<void> _checkAndroidPermission() async {
    if (Theme.of(context).platform == TargetPlatform.android) {
      final status = await Permission.scheduleExactAlarm.status;
      if (status.isDenied && mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text("通知の設定"),
            content: const Text("正確な時間にリマインダーを受け取るには、アラームとリマインダーの権限を許可してください。"),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("後で")),
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await context.read<TodoViewModel>().requestPermission();
                },
                child: const Text("設定する", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _titleController.dispose();
    super.dispose();
  }

  void _onAddPressed() {
    if (_titleController.text.isEmpty) return;

    DateTime initialTime = context.read<TodoViewModel>().normalizeToFiveMinutes(DateTime.now());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return TodoBottomSheet(
          initialTitle: _titleController.text,
          initialDue: initialTime,
          initialReminder: null,
          onSaved: (String title, DateTime due, DateTime? reminder) {
            final isGlobalOn = context.read<SettingsViewModel>().isNotificationOn;
            context.read<TodoViewModel>().addTodo(title, due, reminder, isGlobalOn);
            _titleController.clear();
            FocusScope.of(context).unfocus();
          },
        );
      },
    );
  }

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
        title: const Text("Tasks", style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())),
          ),
        ],
      ),
      body: Consumer2<TodoViewModel, SettingsViewModel>(
        builder: (context, todoVM, settingsVM, child) {
          return Column(
            children: [
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
                          hintText: '新しいタスクを追加...',
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

              Expanded(
                child: todoVM.todos.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.task_alt, size: 60, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text("予定がありません", style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: todoVM.todos.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final todo = todoVM.todos[index];
                          final isOverdue = todo.dueDateTime.isBefore(DateTime.now()) && !todo.isDone;

                          return Slidable(
                            key: ValueKey(todo.id),
                            startActionPane: ActionPane(
                              motion: const ScrollMotion(),
                              children: [
                                SlidableAction(
                                  onPressed: (context) {
                                    bool success = todoVM.togglePin(index, settingsVM.isPremium);

                                    if (!success) {
                                      showCupertinoDialog(
                                        context: context,
                                        builder: (ctx) => CupertinoAlertDialog(
                                          title: const Text("プレミアム機能"),
                                          content: const Text("無料版では1つまで固定できます。\n無制限に固定するにはアップグレードしてください。"),
                                          actions: [
                                            CupertinoDialogAction(child: const Text("キャンセル"), onPressed: () => Navigator.pop(ctx)),
                                            CupertinoDialogAction(
                                              isDefaultAction: true,
                                              child: const Text("詳細を見る"),
                                              onPressed: () {
                                                Navigator.pop(ctx);
                                                Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                                              },
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                    // 성공 시 스낵바 제거됨 (아무 동작 안 함)
                                  },
                                  backgroundColor: Colors.grey[700]!,
                                  foregroundColor: Colors.white,
                                  icon: todo.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                                  label: todo.isPinned ? '解除' : '固定',
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ],
                            ),
                            endActionPane: ActionPane(
                              motion: const ScrollMotion(),
                              children: [
                                SlidableAction(
                                  onPressed: (context) => _onEditPressed(index, todo.title, todo.dueDateTime, todo.reminderTime),
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  icon: Icons.edit,
                                  label: '編集',
                                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                                ),
                                SlidableAction(
                                  onPressed: (context) {
                                    todoVM.deleteTodo(index);
                                    // 삭제 시 스낵바 제거됨
                                  },
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  icon: Icons.delete,
                                  label: '削除',
                                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                                ),
                              ],
                            ),
                            child: Card(
                              margin: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
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
                                        Icon(Icons.calendar_today, size: 14, color: isOverdue ? Colors.red : Colors.grey.shade600),
                                        const SizedBox(width: 4),
                                        Text(
                                          DateFormat('yyyy/MM/dd HH:mm').format(todo.dueDateTime),
                                          style: TextStyle(color: isOverdue ? Colors.red : Colors.grey.shade600, fontSize: 13, fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal),
                                        ),
                                        if (isOverdue)
                                          const Text(
                                            " (期限切れ)",
                                            style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                      ],
                                    ),
                                    if (todo.reminderTime != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.notifications_active, size: 14, color: Colors.orange),
                                            const SizedBox(width: 4),
                                            Text(
                                              DateFormat('MM/dd HH:mm').format(todo.reminderTime!),
                                              style: const TextStyle(color: Colors.orange, fontSize: 13, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: todo.isPinned ? Icon(Icons.push_pin, color: Colors.grey[700], size: 20) : null,
                              ),
                            ),
                          );
                        },
                      ),
              ),

              if (!settingsVM.isPremium)
                Container(
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
                ),
            ],
          );
        },
      ),
    );
  }
}
