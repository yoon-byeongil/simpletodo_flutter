import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/todo_model.dart';

class TodoViewModel extends ChangeNotifier {
  List<Todo> _todos = [];
  List<Todo> get todos => _todos;

  TodoViewModel() {
    _loadTodos();
  }

  void addTodo(String title, DateTime due, DateTime? reminder) {
    _todos.add(Todo(title: title, dueDateTime: due, reminderTime: reminder));
    _sortTodos();
    _saveTodos();
    notifyListeners();
  }

  void toggleDone(int index, bool isAutoDeleteOn) {
    if (index >= _todos.length) return;
    _todos[index].isDone = !_todos[index].isDone;
    _saveTodos();
    notifyListeners();

    if (isAutoDeleteOn && _todos[index].isDone) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (index < _todos.length && _todos[index].isDone) {
          deleteTodo(index); // 아래 만든 삭제 함수 재사용
        }
      });
    }
  }

  // [기능 1] 알림 시간 수정 (켜거나 끄기)
  // newTime이 null이면 끄기, 시간이 있으면 켜기
  void updateReminder(int index, DateTime? newTime) {
    if (index >= _todos.length) return;
    _todos[index].reminderTime = newTime;
    _saveTodos();
    notifyListeners();
  }

  // [기능 2] 일정 아예 삭제하기
  void deleteTodo(int index) {
    if (index >= _todos.length) return;
    _todos.removeAt(index);
    _saveTodos();
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
