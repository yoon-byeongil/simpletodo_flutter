import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

// ▼ 뷰모델 파일 위치를 정확히 가리켜야 합니다.
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

  void _onAddPressed() async {
    if (_titleController.text.isEmpty) return;

    final DateTime? pickedDate = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2030));

    if (!mounted) return;
    if (pickedDate == null) return;

    final TimeOfDay? pickedTime = await showTimePicker(context: context, initialTime: TimeOfDay.now());

    if (!mounted) return;
    if (pickedTime == null) return;

    final DateTime dueDateTime = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);

    context.read<TodoViewModel>().addTodo(_titleController.text, dueDateTime, context.read<SettingsViewModel>().isNotificationOn ? dueDateTime : null);

    _titleController.clear();
    FocusScope.of(context).unfocus();
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
                    decoration: const InputDecoration(hintText: '할 일을 입력하세요', border: OutlineInputBorder()),
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
                  return const Center(child: Text("일정이 없습니다."));
                }
                return ListView.builder(
                  itemCount: todoVM.todos.length,
                  itemBuilder: (context, index) {
                    final todo = todoVM.todos[index];
                    return ListTile(
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
                      subtitle: Text(DateFormat('MM/dd HH:mm').format(todo.dueDateTime), style: const TextStyle(color: Colors.blueGrey)),
                      trailing: todo.reminderTime != null ? const Icon(Icons.alarm, size: 16, color: Colors.orange) : null,
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
