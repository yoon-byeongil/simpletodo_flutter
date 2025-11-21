import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // [필수] 아이폰 스타일 위젯
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
      builder: (context) {
        return AddTodoBottomSheet(
          initialTitle: _titleController.text,
          onSaved: (DateTime due, DateTime? reminder) {
            // [수정] ViewModel에 '현재 전체 알림 설정 값'을 같이 보냄
            final isGlobalOn = context.read<SettingsViewModel>().isNotificationOn;

            context.read<TodoViewModel>().addTodo(
              _titleController.text,
              due,
              reminder,
              isGlobalOn, // 여기!
            );
            _titleController.clear();
            FocusScope.of(context).unfocus();
          },
        );
      },
    );
  }

  // [아이폰 스타일] 알림 시간 선택 피커
  Future<void> _showCupertinoReminderPicker(int index, DateTime initialDate) async {
    DateTime tempPickedDate = initialDate;

    await showCupertinoModalPopup(
      context: context,
      builder: (ctx) {
        return Container(
          height: 300,
          color: Colors.white, // 다크모드 대응 시 수정 필요 (Theme.of(context).scaffoldBackgroundColor)
          child: Column(
            children: [
              // 상단 완료 버튼 바
              Container(
                color: Colors.grey[200],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [CupertinoButton(child: const Text("완료"), onPressed: () => Navigator.pop(ctx))],
                ),
              ),
              // 룰렛 피커
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.dateAndTime, // 날짜+시간 한번에
                  initialDateTime: initialDate,
                  minimumDate: DateTime.now(), // 과거 시간 선택 불가
                  use24hFormat: true,
                  onDateTimeChanged: (DateTime date) {
                    tempPickedDate = date;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted) return;

    // [수정] ViewModel에 '현재 전체 알림 설정 값'을 같이 보냄
    final isGlobalOn = context.read<SettingsViewModel>().isNotificationOn;
    context.read<TodoViewModel>().updateReminder(index, tempPickedDate, isGlobalOn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Simple Todo"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(hintText: '할 일을 입력하세요', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filled(onPressed: _onAddPressed, icon: const Icon(Icons.add)),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Consumer2<TodoViewModel, SettingsViewModel>(
              builder: (context, todoVM, settingsVM, child) {
                if (todoVM.todos.isEmpty) {
                  return const Center(child: Text("할 일이 없습니다.\n+ 버튼을 눌러 추가해보세요!", textAlign: TextAlign.center));
                }
                return ListView.builder(
                  itemCount: todoVM.todos.length,
                  itemBuilder: (context, index) {
                    final todo = todoVM.todos[index];

                    return Dismissible(
                      key: ValueKey(todo.title + todo.dueDateTime.toString()),
                      direction: DismissDirection.endToStart,
                      onDismissed: (direction) {
                        todoVM.deleteTodo(index);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("'${todo.title}' 삭제됨")));
                      },
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      child: ListTile(
                        leading: Checkbox(
                          value: todo.isDone,
                          onChanged: (value) {
                            todoVM.toggleDone(index, settingsVM.isAutoDelete);
                          },
                        ),
                        title: Text(
                          todo.title,
                          style: TextStyle(decoration: todo.isDone ? TextDecoration.lineThrough : null, color: todo.isDone ? Colors.grey : null),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(DateFormat('MM/dd HH:mm 마감').format(todo.dueDateTime)),
                            if (todo.reminderTime != null) Text("🔔 ${DateFormat('MM/dd HH:mm').format(todo.reminderTime!)}", style: const TextStyle(color: Colors.orange, fontSize: 12)),
                          ],
                        ),
                        trailing: IconButton(
                          icon: Icon(todo.reminderTime != null ? Icons.notifications_active : Icons.notifications_off_outlined, color: todo.reminderTime != null ? Colors.orange : Colors.grey),
                          onPressed: () {
                            if (todo.reminderTime != null) {
                              // 알림 해제
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text("알림 해제"),
                                  content: const Text("알림을 끄시겠습니까?"),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("취소")),
                                    TextButton(
                                      onPressed: () {
                                        // [수정] isGlobalOn 전달
                                        todoVM.updateReminder(index, null, settingsVM.isNotificationOn);
                                        Navigator.pop(ctx);
                                      },
                                      child: const Text("해제"),
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              // 알림 설정 (Cupertino 피커 호출)
                              _showCupertinoReminderPicker(index, todo.dueDateTime);
                            }
                          },
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

// Bottom Sheet 수정 (Cupertino 적용)
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
    // 분 단위 00으로 깔끔하게 맞추기 (선택사항)
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day, now.hour, now.minute);
  }

  // [아이폰 스타일] 날짜+시간 선택 팝업
  void _showCupertinoDatePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Container(
        height: 250,
        color: Colors.white,
        child: Column(
          children: [
            Container(
              color: Colors.grey[200],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [CupertinoButton(child: const Text("완료"), onPressed: () => Navigator.pop(ctx))],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.dateAndTime,
                initialDateTime: _selectedDate,
                minimumDate: DateTime.now().subtract(const Duration(minutes: 1)),
                use24hFormat: true,
                onDateTimeChanged: (DateTime newDate) {
                  setState(() => _selectedDate = newDate);
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

    return Container(
      padding: const EdgeInsets.all(20),
      height: 400,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("'${widget.initialTitle}' 상세 설정", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),

          const Text("📅 마감 일정", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 10),

          // [수정] 버튼 하나로 통합하고 Cupertino 피커 호출
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _showCupertinoDatePicker,
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
              child: Text(
                DateFormat('yyyy-MM-dd  HH:mm').format(_selectedDate),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
            ),
          ),

          const SizedBox(height: 20),

          const Text("🔔 알림 설정", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 10),

          // 알림 설정 부분 UI 유지 (Global 설정 안내는 그대로 유효)
          if (!isGlobalNotiOn)
            const Text("설정 메뉴에서 '알림 켜기'가 꺼져있어 알림이 울리지 않습니다.", style: TextStyle(color: Colors.redAccent, fontSize: 13))
          else
            DropdownButtonFormField<int>(
              value: _reminderOption,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 0, child: Text("알림 없음")),
                DropdownMenuItem(value: 1, child: Text("정각 (마감 시간)")),
                DropdownMenuItem(value: 2, child: Text("10분 전")),
                DropdownMenuItem(value: 3, child: Text("1시간 전")),
              ],
              onChanged: (value) {
                setState(() => _reminderOption = value!);
              },
            ),

          const Spacer(),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: () {
                DateTime? reminderTime;
                // Global 설정이 켜져있어야만 알림 시간 계산 (UI 표시용)
                // 실제 스케줄링 차단은 ViewModel에서 한번 더 방어함
                if (isGlobalNotiOn && _reminderOption != 0) {
                  if (_reminderOption == 1) reminderTime = _selectedDate;
                  if (_reminderOption == 2) reminderTime = _selectedDate.subtract(const Duration(minutes: 10));
                  if (_reminderOption == 3) reminderTime = _selectedDate.subtract(const Duration(hours: 1));
                }

                widget.onSaved(_selectedDate, reminderTime);
                Navigator.pop(context);
              },
              child: const Text("저장"),
            ),
          ),
        ],
      ),
    );
  }
}
