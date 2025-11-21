import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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

  void _onAddPressed() {
    if (_titleController.text.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return AddTodoBottomSheet(
          initialTitle: _titleController.text,
          onSaved: (DateTime due, DateTime? reminder) {
            final isGlobalOn = context.read<SettingsViewModel>().isNotificationOn;
            context.read<TodoViewModel>().addTodo(_titleController.text, due, reminder, isGlobalOn);
            _titleController.clear();
            FocusScope.of(context).unfocus();
          },
        );
      },
    );
  }

  Future<void> _showCupertinoReminderPicker(int index, DateTime initialDate) async {
    DateTime tempPickedDate = initialDate;
    // 다크모드 여부 확인
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showCupertinoModalPopup(
      context: context,
      builder: (ctx) {
        return Container(
          height: 300,
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white, // [수정] 배경색 동적 변경
          child: Column(
            children: [
              Container(
                color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF0F0F0), // [수정] 상단바 색상
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      child: const Text("キャンセル", style: TextStyle(color: Colors.grey)),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                    CupertinoButton(
                      child: const Text("完了", style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.dateAndTime,
                  initialDateTime: initialDate,
                  // [오류 해결 핵심] 현재 시간보다 5분 전부터 선택 가능하게 해서 충돌 방지
                  minimumDate: DateTime.now().subtract(const Duration(minutes: 5)),
                  use24hFormat: true,
                  onDateTimeChanged: (date) => tempPickedDate = date,
                ),
              ),
            ],
          ),
        );
      },
    );
    if (!mounted) return;
    final isGlobalOn = context.read<SettingsViewModel>().isNotificationOn;
    context.read<TodoViewModel>().updateReminder(index, tempPickedDate, isGlobalOn);
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
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 입력창 영역
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor, // [수정] 테마 색상 사용
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
                      // [수정] 입력창 배경색 (다크모드 대응)
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

          // 리스트 영역
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

                    return Dismissible(
                      key: ValueKey(todo.title + todo.dueDateTime.toString()),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) {
                        todoVM.deleteTodo(index);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("'${todo.title}' 削除しました")));
                      },
                      background: Container(
                        decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(12)),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete_outline, color: Colors.white),
                      ),
                      child: Card(
                        margin: EdgeInsets.zero,
                        // [수정] CardColor는 main.dart에서 정의한 값을 자동으로 따라갑니다.
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
                              // [수정] 글자색 테마 대응
                              color: todo.isDone ? Colors.grey : Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(DateFormat('yyyy/MM/dd HH:mm').format(todo.dueDateTime), style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                if (todo.reminderTime != null) ...[
                                  const SizedBox(width: 8),
                                  const Icon(Icons.notifications_active, size: 14, color: Colors.orange),
                                  const SizedBox(width: 2),
                                  Text(
                                    DateFormat('HH:mm').format(todo.reminderTime!),
                                    style: const TextStyle(color: Colors.orange, fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              todo.reminderTime != null ? Icons.notifications : Icons.notifications_none,
                              color: todo.reminderTime != null ? Theme.of(context).primaryColor : Colors.grey.shade400,
                            ),
                            onPressed: () {
                              if (todo.reminderTime != null) {
                                showCupertinoDialog(
                                  context: context,
                                  builder: (ctx) => CupertinoAlertDialog(
                                    title: const Text("通知オフ"),
                                    content: const Text("このタスクの通知をオフにしますか？"),
                                    actions: [
                                      CupertinoDialogAction(child: const Text("キャンセル"), onPressed: () => Navigator.pop(ctx)),
                                      CupertinoDialogAction(
                                        isDestructiveAction: true,
                                        child: const Text("オフにする"),
                                        onPressed: () {
                                          todoVM.updateReminder(index, null, settingsVM.isNotificationOn);
                                          Navigator.pop(ctx);
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              } else {
                                _showCupertinoReminderPicker(index, todo.dueDateTime);
                              }
                            },
                          ),
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

class AddTodoBottomSheet extends StatefulWidget {
  final String initialTitle;
  final Function(DateTime due, DateTime? reminder) onSaved;

  const AddTodoBottomSheet({super.key, required this.initialTitle, required this.onSaved});

  @override
  State<AddTodoBottomSheet> createState() => _AddTodoBottomSheetState();
}

class _AddTodoBottomSheetState extends State<AddTodoBottomSheet> {
  late DateTime _selectedDate;
  int _reminderOption = 1;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day, now.hour, now.minute);
  }

  void _showCupertinoDatePicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Container(
        height: 280,
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white, // [수정] 배경색 대응
        child: Column(
          children: [
            Container(
              color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF0F0F0), // [수정] 상단바 대응
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
                mode: CupertinoDatePickerMode.dateAndTime,
                initialDateTime: _selectedDate,
                // [오류 해결 핵심] 5분 전부터 선택 가능하게 해서 충돌 방지
                minimumDate: DateTime.now().subtract(const Duration(minutes: 5)),
                use24hFormat: true,
                onDateTimeChanged: (newDate) => setState(() => _selectedDate = newDate),
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
    // [수정] 다크모드인지 확인
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, // [수정] 배경색 테마 대응
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      height: 450,
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
          Text(
            widget.initialTitle,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 30),

          const Text(
            "締め切り (Deadline)",
            style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _showCupertinoDatePicker,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300), // [수정] 테두리 색상
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month, color: Colors.blueAccent),
                  const SizedBox(width: 10),
                  Text(DateFormat('yyyy/MM/dd HH:mm').format(_selectedDate), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            "通知設定 (Notification)",
            style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          if (!isGlobalNotiOn)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: const Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text("設定で「通知」をオンにしてください。", style: TextStyle(color: Colors.red, fontSize: 13)),
                  ),
                ],
              ),
            )
          else
            DropdownButtonFormField<int>(
              value: _reminderOption,
              dropdownColor: isDark ? const Color(0xFF2C2C2E) : Colors.white, // [수정] 드롭다운 메뉴 배경색
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              ),
              items: const [
                DropdownMenuItem(value: 0, child: Text("なし (None)")),
                DropdownMenuItem(value: 1, child: Text("時間通り (On Time)")),
                DropdownMenuItem(value: 2, child: Text("10分前 (10 min before)")),
                DropdownMenuItem(value: 3, child: Text("1時間前 (1 hour before)")),
              ],
              onChanged: (value) => setState(() => _reminderOption = value!),
            ),

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
                DateTime? reminderTime;
                if (isGlobalNotiOn && _reminderOption != 0) {
                  if (_reminderOption == 1) reminderTime = _selectedDate;
                  if (_reminderOption == 2) reminderTime = _selectedDate.subtract(const Duration(minutes: 10));
                  if (_reminderOption == 3) reminderTime = _selectedDate.subtract(const Duration(hours: 1));
                }
                widget.onSaved(_selectedDate, reminderTime);
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
