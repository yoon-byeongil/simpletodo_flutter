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

  // 1. 추가
  void addTodo(String title, DateTime due, DateTime? reminder, bool isGlobalOn) {
    int newId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final newTodo = Todo(id: newId, title: title, dueDateTime: due, reminderTime: reminder);
    _todos.add(newTodo);

    // [수정] 과거 시간이면 즉시 알림, 미래면 예약
    if (reminder != null && isGlobalOn) {
      if (reminder.isBefore(DateTime.now())) {
        _notificationService.showImmediateNotification(id: newId, title: title);
      } else {
        _notificationService.scheduleNotification(id: newId, title: title, scheduledTime: reminder);
      }
    }

    _sortTodos();
    _saveTodos();
    notifyListeners();
  }

  // 2. 수정
  void editTodo(int index, String newTitle, DateTime newDue, DateTime? newReminder, bool isGlobalOn) {
    if (index >= _todos.length) return;
    final todo = _todos[index];
    todo.title = newTitle;
    todo.dueDateTime = newDue;
    todo.reminderTime = newReminder;

    _notificationService.cancelNotification(todo.id);

    // [수정] 과거 시간이면 즉시 알림, 미래면 예약
    if (newReminder != null && isGlobalOn) {
      if (newReminder.isBefore(DateTime.now())) {
        _notificationService.showImmediateNotification(id: todo.id, title: newTitle);
      } else {
        _notificationService.scheduleNotification(id: todo.id, title: newTitle, scheduledTime: newReminder);
      }
    }

    _sortTodos();
    _saveTodos();
    notifyListeners();
  }

  // ... (togglePin, toggleDone, deleteTodo, deleteOverdueTodos, clearAllTodos, cancelAllReminders 등 기존 코드는 변경 없음. 그대로 유지) ...

  void togglePin(int index) {
    if (index >= _todos.length) return;
    final targetTodo = _todos[index];
    if (!targetTodo.isPinned) {
      for (var todo in _todos) {
        todo.isPinned = false;
      }
    }
    targetTodo.isPinned = !targetTodo.isPinned;
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
      // 업데이트 시에도 과거면 즉시 알림
      if (newTime.isBefore(DateTime.now())) {
        _notificationService.showImmediateNotification(id: todo.id, title: todo.title);
      } else {
        _notificationService.scheduleNotification(id: todo.id, title: todo.title, scheduledTime: newTime);
      }
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

  void deleteOverdueTodos() {
    final now = DateTime.now();
    for (var todo in _todos) {
      if (todo.dueDateTime.isBefore(now)) {
        _notificationService.cancelNotification(todo.id);
      }
    }
    _todos.removeWhere((todo) => todo.dueDateTime.isBefore(now));
    _saveTodos();
    notifyListeners();
  }

  void clearAllTodos() {
    _todos.clear();
    _notificationService.cancelAll();
    _saveTodos();
    notifyListeners();
  }

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
    _todos.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return a.dueDateTime.compareTo(b.dueDateTime);
    });
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
