import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../model/todo_model.dart';
import '../service/notification_service.dart';

class TodoViewModel extends ChangeNotifier {
  List<Todo> _todos = [];
  List<Todo> get todos => _todos;
  final NotificationService _notificationService = NotificationService();

  TodoViewModel() {
    _loadTodos();
  }

  DateTime normalizeToFiveMinutes(DateTime time) {
    int minute = time.minute;
    int remainder = minute % 5;
    int add = (remainder == 0) ? 0 : (5 - remainder);
    return time.add(Duration(minutes: add)).copyWith(second: 0, millisecond: 0);
  }

  Future<bool> checkPermissionStatus() async {
    final status = await Permission.scheduleExactAlarm.status;
    return status.isDenied;
  }

  Future<void> requestPermission() async {
    await Permission.scheduleExactAlarm.request();
  }

  void addTodo(String title, DateTime due, DateTime? reminder, bool isGlobalOn) {
    int newId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final newTodo = Todo(id: newId, title: title, dueDateTime: due, reminderTime: reminder);
    _todos.add(newTodo);

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

  void editTodo(int index, String newTitle, DateTime newDue, DateTime? newReminder, bool isGlobalOn) {
    if (index >= _todos.length) return;
    final todo = _todos[index];
    todo.title = newTitle;
    todo.dueDateTime = newDue;
    todo.reminderTime = newReminder;

    _notificationService.cancelNotification(todo.id);

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

  // [수정] 핀 고정 토글 (성공/실패 반환)
  bool togglePin(int index, bool isPremium) {
    if (index >= _todos.length) return false;
    final targetTodo = _todos[index];

    // 이미 고정된 걸 해제하는 건 무조건 허용
    if (targetTodo.isPinned) {
      targetTodo.isPinned = false;
      _sortTodos();
      _saveTodos();
      notifyListeners();
      return true; // 성공
    }

    // [BM] 새로 고정하려는데 프리미엄이 아니고, 이미 1개 이상 고정되어 있다면?
    int pinnedCount = _todos.where((t) => t.isPinned).length;
    if (!isPremium && pinnedCount >= 1) {
      return false; // 실패 (돈 내라고 팝업 띄울 예정)
    }

    // 허용
    targetTodo.isPinned = true;
    _sortTodos();
    _saveTodos();
    notifyListeners();
    return true; // 성공
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
