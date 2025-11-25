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

    if (reminder != null && isGlobalOn) {
      _notificationService.scheduleNotification(id: newId, title: title, scheduledTime: reminder);
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

    // 기존 알림 취소 후 재등록
    _notificationService.cancelNotification(todo.id);
    if (newReminder != null && isGlobalOn) {
      _notificationService.scheduleNotification(id: todo.id, title: newTitle, scheduledTime: newReminder);
    }

    _sortTodos();
    _saveTodos();
    notifyListeners();
  }

  // 3. 고정 (Pin) 토글
  void togglePin(int index) {
    if (index >= _todos.length) return;

    final targetTodo = _todos[index];

    // 하나만 고정되도록 다른 핀은 해제
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

  // 4. 완료 체크
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

  // 5. 알림 시간만 수정
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

  // 6. 삭제
  void deleteTodo(int index) {
    if (index >= _todos.length) return;
    _notificationService.cancelNotification(_todos[index].id);
    _todos.removeAt(index);
    _saveTodos();
    notifyListeners();
  }

  // 7. [추가된 기능] 시간이 지난(Overdue) 일정 일괄 삭제
  void deleteOverdueTodos() {
    final now = DateTime.now();

    // 삭제될 항목들의 알림 취소
    for (var todo in _todos) {
      if (todo.dueDateTime.isBefore(now)) {
        _notificationService.cancelNotification(todo.id);
      }
    }

    // 리스트에서 제거
    _todos.removeWhere((todo) => todo.dueDateTime.isBefore(now));

    _saveTodos();
    notifyListeners();
  }

  // 8. 전체 초기화
  void clearAllTodos() {
    _todos.clear();
    _notificationService.cancelAll();
    _saveTodos();
    notifyListeners();
  }

  // 9. 설정용 - 알림 일괄 취소
  void cancelAllReminders() {
    _notificationService.cancelAll();
    notifyListeners();
  }

  // 10. 설정용 - 알림 일괄 복구
  void restoreAllReminders() {
    final now = DateTime.now();
    for (var todo in _todos) {
      if (!todo.isDone && todo.reminderTime != null && todo.reminderTime!.isAfter(now)) {
        _notificationService.scheduleNotification(id: todo.id, title: todo.title, scheduledTime: todo.reminderTime!);
      }
    }
    notifyListeners();
  }

  // 정렬 (핀 > 날짜순)
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
