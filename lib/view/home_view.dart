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
                  await Permission.scheduleExactAlarm.request();
                },
                child: const Text("設定する", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    }
  }

  DateTime _getNearestFiveMinuteInterval(DateTime time) {
    int minute = time.minute;
    int remainder = minute % 5;
    int add = (remainder == 0) ? 0 : (5 - remainder);
    return time.add(Duration(minutes: add)).copyWith(second: 0, millisecond: 0);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _titleController.dispose();
    super.dispose();
  }

  void _onAddPressed() {
    if (_titleController.text.isEmpty) return;

    DateTime initialTime = _getNearestFiveMinuteInterval(DateTime.now());

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
      body: Column(
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
            child: Consumer2<TodoViewModel, SettingsViewModel>(
              builder: (context, todoVM, settingsVM, child) {
                if (todoVM.todos.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.task_alt, size: 60, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text("予定がありません", style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                      ],
                    ),
                  );
                }
                return ListView.separated(
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
                              todoVM.togglePin(index);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(todo.isPinned ? "固定を解除しました" : "タスクを固定しました"), duration: const Duration(seconds: 1)));
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
                            onPressed: (context) {
                              _onEditPressed(index, todo.title, todo.dueDateTime, todo.reminderTime);
                            },
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            icon: Icons.edit,
                            label: '編集',
                            borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                          ),
                          SlidableAction(
                            onPressed: (context) {
                              todoVM.deleteTodo(index);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("削除しました")));
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class TodoBottomSheet extends StatefulWidget {
  final String initialTitle;
  final DateTime initialDue;
  final DateTime? initialReminder;
  final Function(String title, DateTime due, DateTime? reminder) onSaved;

  const TodoBottomSheet({super.key, required this.initialTitle, required this.initialDue, required this.initialReminder, required this.onSaved});

  @override
  State<TodoBottomSheet> createState() => _TodoBottomSheetState();
}

class _TodoBottomSheetState extends State<TodoBottomSheet> {
  late TextEditingController _textController;
  late DateTime _deadlineDate;
  bool _isReminderEnabled = false;
  late DateTime _reminderDate;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialTitle);
    _deadlineDate = widget.initialDue;

    if (widget.initialReminder != null) {
      _isReminderEnabled = true;
      _reminderDate = _getNearestFiveMinuteInterval(widget.initialReminder!);
    } else {
      _isReminderEnabled = false;
      _reminderDate = _getNearestFiveMinuteInterval(DateTime.now());
    }
    _deadlineDate = _getNearestFiveMinuteInterval(_deadlineDate);
  }

  DateTime _getNearestFiveMinuteInterval(DateTime time) {
    int minute = time.minute;
    int remainder = minute % 5;
    int add = (remainder == 0) ? 0 : (5 - remainder);
    return time.add(Duration(minutes: add)).copyWith(second: 0, millisecond: 0);
  }

  // [수정] 날짜 선택 - 아이폰 스타일 슬라이더 (연-월-일 순)
  void _pickDate(bool isDeadline) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    DateTime initial = isDeadline ? _deadlineDate : _reminderDate;

    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Container(
        height: 250,
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        child: Column(
          children: [
            Container(
              color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF0F0F0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CupertinoButton(
                    child: const Text("完了", style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Localizations.override(
                context: context,
                locale: const Locale('ja'),
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: initial,
                  minimumDate: DateTime(2020),
                  maximumDate: DateTime(2100),
                  // 일본어 로케일에서는 자동으로 '년월일'이 붙지만, 순서 보장을 위해 ymd 설정
                  dateOrder: DatePickerDateOrder.ymd,
                  use24hFormat: true,
                  onDateTimeChanged: (newDate) {
                    setState(() {
                      if (isDeadline) {
                        _deadlineDate = DateTime(newDate.year, newDate.month, newDate.day, _deadlineDate.hour, _deadlineDate.minute);
                      } else {
                        _reminderDate = DateTime(newDate.year, newDate.month, newDate.day, _reminderDate.hour, _reminderDate.minute);
                      }
                    });
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 시간 선택 (5분 단위 룰렛)
  void _pickTime(bool isDeadline) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    DateTime initial = isDeadline ? _deadlineDate : _reminderDate;

    // 룰렛 열기 전 5분 단위 보정
    initial = _getNearestFiveMinuteInterval(initial);

    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Container(
        height: 250,
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        child: Column(
          children: [
            Container(
              color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF0F0F0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CupertinoButton(
                    child: const Text("完了", style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                initialDateTime: initial,
                minuteInterval: 5,
                use24hFormat: true,
                onDateTimeChanged: (newTime) {
                  setState(() {
                    if (isDeadline) {
                      _deadlineDate = DateTime(_deadlineDate.year, _deadlineDate.month, _deadlineDate.day, newTime.hour, newTime.minute);
                    } else {
                      _reminderDate = DateTime(_reminderDate.year, _reminderDate.month, _reminderDate.day, newTime.hour, newTime.minute);
                    }
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isGlobalNotiOn = context.watch<SettingsViewModel>().isNotificationOn;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      height: 650,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),

          TextField(
            controller: _textController,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(hintText: "タスク名", border: InputBorder.none),
          ),
          const Divider(),
          const SizedBox(height: 10),

          const Text(
            "締め切り (Deadline)",
            style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: InkWell(
                  onTap: () => _pickDate(true),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month, color: Colors.blueAccent, size: 20),
                        const SizedBox(width: 8),
                        Text(DateFormat('yyyy/MM/dd').format(_deadlineDate), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: InkWell(
                  onTap: () => _pickTime(true),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.access_time, color: Colors.blueAccent, size: 20),
                        const SizedBox(width: 8),
                        Text(DateFormat('HH:mm').format(_deadlineDate), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "通知設定 (Notification)",
                style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              Switch.adaptive(
                value: _isReminderEnabled,
                onChanged: (val) {
                  setState(() => _isReminderEnabled = val);
                },
              ),
            ],
          ),

          if (_isReminderEnabled) ...[
            if (!isGlobalNotiOn)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text("※ 設定で通知がオフになっています。", style: TextStyle(color: Colors.red.shade400, fontSize: 12)),
              ),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: InkWell(
                    onTap: () => _pickDate(false),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.orange.shade300),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.orange.withOpacity(0.05),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.notifications_active, color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('yyyy/MM/dd').format(_reminderDate),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.orange),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: InkWell(
                    onTap: () => _pickTime(false),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.orange.shade300),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.orange.withOpacity(0.05),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.access_time, color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('HH:mm').format(_reminderDate),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.orange),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],

          const Spacer(),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton(
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                backgroundColor: Theme.of(context).primaryColor,
              ),
              onPressed: () {
                widget.onSaved(_textController.text, _deadlineDate, _isReminderEnabled ? _reminderDate : null);
                Navigator.pop(context);
              },
              child: const Text("保存する", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
