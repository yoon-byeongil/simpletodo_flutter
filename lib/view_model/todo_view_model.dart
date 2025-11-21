import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/todo_model.dart';
import '../service/notification_service.dart';

class TodoViewModel extends ChangeNotifier {
  List<Todo> _todos = [];
  List<Todo> get todos => _todos;
  final NotificationService _notificationService = NotificationService();

  TodoViewModel() {
    _loadTodos();
  }

  void addTodo(String title, DateTime due, DateTime? reminder, bool isGlobalOn) {
    int newId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final newTodo = Todo(id: newId, title: title, dueDateTime: due, reminderTime: reminder);

    _todos.add(newTodo);

    if (reminder != null && isGlobalOn) {
      _notificationService.scheduleNotification(id: newId, title: title, scheduledTime: reminder);
    }

    _sortTodos();
    _saveTodos();
    notifyListeners();
  }

  void toggleDone(int index, bool isAutoDeleteOn) {
    if (index >= _todos.length) return;
    _todos[index].isDone = !_todos[index].isDone;

    if (_todos[index].isDone) {
      _notificationService.cancelNotification(_todos[index].id);
    }

    _saveTodos();
    notifyListeners();

    if (isAutoDeleteOn && _todos[index].isDone) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (index < _todos.length && _todos[index].isDone) {
          deleteTodo(index);
        }
      });
    }
  }

  void updateReminder(int index, DateTime? newTime, bool isGlobalOn) {
    if (index >= _todos.length) return;

    final todo = _todos[index];
    todo.reminderTime = newTime;

    _notificationService.cancelNotification(todo.id);

    if (newTime != null && isGlobalOn) {
      _notificationService.scheduleNotification(id: todo.id, title: todo.title, scheduledTime: newTime);
    }

    _saveTodos();
    notifyListeners();
  }

  void deleteTodo(int index) {
    if (index >= _todos.length) return;
    _notificationService.cancelNotification(_todos[index].id);
    _todos.removeAt(index);
    _saveTodos();
    notifyListeners();
  }

  // ▼▼▼ [이 부분이 빠져 있어서 오류가 났던 겁니다!] ▼▼▼
  void clearAllTodos() {
    _todos.clear(); // 리스트 비우기
    _notificationService.cancelAll(); // 알림 다 끄기
    _saveTodos(); // 빈 리스트 저장
    notifyListeners(); // 화면 갱신
  }
  // ▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲

  void cancelAllReminders() {
    _notificationService.cancelAll();
    notifyListeners();
  }

  void restoreAllReminders() {
    final now = DateTime.now();
    for (var todo in _todos) {
      if (!todo.isDone && todo.reminderTime != null && todo.reminderTime!.isAfter(now)) {
        _notificationService.scheduleNotification(id: todo.id, title: todo.title, scheduledTime: todo.reminderTime!);
      }
    }
    notifyListeners();
  }

  void _sortTodos() {
    _todos.sort((a, b) => a.dueDateTime.compareTo(b.dueDateTime));
  }

  Future<void> _saveTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = jsonEncode(_todos.map((e) => e.toJson()).toList());
    await prefs.setString('todo_list', encodedData);
  }

  Future<void> _loadTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString('todo_list');
    if (jsonString != null) {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      _todos = jsonList.map((e) => Todo.fromJson(e)).toList();
      notifyListeners();
    }
  }
}
