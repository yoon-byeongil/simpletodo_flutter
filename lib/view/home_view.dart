import 'package:flutter/material.dart';
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
            context.read<TodoViewModel>().addTodo(_titleController.text, due, reminder);
            _titleController.clear();
            FocusScope.of(context).unfocus();
          },
        );
      },
    );
  }

  // 알림을 켜기 위한 시간 선택 다이얼로그
  Future<void> _showReminderPicker(int index, DateTime dueDateTime) async {
    // 기본값: 마감 시간과 동일하게 설정할지 물어봄
    final DateTime? pickedDate = await showDatePicker(context: context, initialDate: dueDateTime, firstDate: DateTime.now(), lastDate: DateTime(2030), helpText: "알림 날짜 선택");
    if (pickedDate == null) return;
    if (!mounted) return;

    final TimeOfDay? pickedTime = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(dueDateTime), helpText: "알림 시간 선택");
    if (pickedTime == null) return;

    final newReminder = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);

    if (mounted) {
      context.read<TodoViewModel>().updateReminder(index, newReminder);
    }
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

                    // [기능 2] 옆으로 밀어서 삭제 (Dismissible)
                    return Dismissible(
                      // 각 아이템을 구분하는 고유 키 (제목+시간으로 임시 생성)
                      key: ValueKey(todo.title + todo.dueDateTime.toString()),
                      direction: DismissDirection.endToStart, // 오른쪽에서 왼쪽으로만
                      onDismissed: (direction) {
                        // 실제 삭제 로직 수행
                        todoVM.deleteTodo(index);

                        // 하단에 잠시 스낵바(안내문구) 띄우기
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("'${todo.title}' 삭제됨")));
                      },
                      // 밀었을 때 뒤에 보이는 빨간 배경 설정
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
                        // [기능 1] 알림 켜기/끄기 버튼
                        trailing: IconButton(
                          icon: Icon(
                            todo.reminderTime != null
                                ? Icons
                                      .notifications_active // 알림 있음 (켜짐)
                                : Icons.notifications_off_outlined, // 알림 없음 (꺼짐)
                            color: todo.reminderTime != null ? Colors.orange : Colors.grey,
                          ),
                          onPressed: () {
                            if (todo.reminderTime != null) {
                              // 알림이 있으면 -> 삭제하시겠습니까?
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text("알림 해제"),
                                  content: const Text("알림을 끄시겠습니까?"),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("취소")),
                                    TextButton(
                                      onPressed: () {
                                        todoVM.updateReminder(index, null); // null로 업데이트하여 삭제
                                        Navigator.pop(ctx);
                                      },
                                      child: const Text("해제"),
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              // 알림이 없으면 -> 새로 설정 (시간 선택창 띄우기)
                              _showReminderPicker(index, todo.dueDateTime);
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

// (AddTodoBottomSheet 클래스는 이전 코드와 동일하므로 생략해도 되지만,
//  혹시 모르니 그대로 두시거나 이전 코드의 class를 그대로 쓰시면 됩니다.)
class AddTodoBottomSheet extends StatefulWidget {
  final String initialTitle;
  final Function(DateTime due, DateTime? reminder) onSaved;

  const AddTodoBottomSheet({super.key, required this.initialTitle, required this.onSaved});

  @override
  State<AddTodoBottomSheet> createState() => _AddTodoBottomSheetState();
}

class _AddTodoBottomSheetState extends State<AddTodoBottomSheet> {
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  int _reminderOption = 1;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _selectedTime = TimeOfDay.now();
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
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final date = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime.now(), lastDate: DateTime(2030));
                    if (date != null) setState(() => _selectedDate = date);
                  },
                  child: Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final time = await showTimePicker(context: context, initialTime: _selectedTime);
                    if (time != null) setState(() => _selectedTime = time);
                  },
                  child: Text(_selectedTime.format(context)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          const Text("🔔 알림 설정", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 10),
          if (!isGlobalNotiOn)
            const Text("설정 메뉴에서 '알림 켜기'를 활성화해주세요.", style: TextStyle(color: Colors.redAccent))
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
                final dueDateTime = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _selectedTime.hour, _selectedTime.minute);

                DateTime? reminderTime;
                if (isGlobalNotiOn && _reminderOption != 0) {
                  if (_reminderOption == 1) reminderTime = dueDateTime;
                  if (_reminderOption == 2) reminderTime = dueDateTime.subtract(const Duration(minutes: 10));
                  if (_reminderOption == 3) reminderTime = dueDateTime.subtract(const Duration(hours: 1));
                }

                widget.onSaved(dueDateTime, reminderTime);
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
