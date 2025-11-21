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

  // [수정] isGlobalOn 파라미터 추가
  void addTodo(String title, DateTime due, DateTime? reminder, bool isGlobalOn) {
    int newId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final newTodo = Todo(id: newId, title: title, dueDateTime: due, reminderTime: reminder);

    _todos.add(newTodo);

    // [핵심 로직] 전체 알림이 켜져 있을 때만 스케줄링 등록
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

  // [수정] isGlobalOn 파라미터 추가
  void updateReminder(int index, DateTime? newTime, bool isGlobalOn) {
    if (index >= _todos.length) return;

    final todo = _todos[index];
    todo.reminderTime = newTime;

    // 기존 알림 취소
    _notificationService.cancelNotification(todo.id);

    // [핵심 로직] 전체 알림이 켜져 있을 때만 재등록
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

  void cancelAllReminders() {
    _notificationService.cancelAll();
    notifyListeners();
  }

  // [추가 기능 2] 설정 ON 시 -> 리스트를 돌면서 미래의 알림들 다시 예약
  void restoreAllReminders() {
    final now = DateTime.now();
    for (var todo in _todos) {
      // 완료되지 않았고, 알림 시간이 있고, 미래인 경우만 재등록
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
