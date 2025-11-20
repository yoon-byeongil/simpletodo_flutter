import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simpletodo_flutter/model/todo_model.dart';

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
    if (index >= _todos.length) return; // 안전장치
    _todos[index].isDone = !_todos[index].isDone;
    _saveTodos();
    notifyListeners();

    if (isAutoDeleteOn && _todos[index].isDone) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (index < _todos.length && _todos[index].isDone) {
          _todos.removeAt(index);
          _saveTodos();
          notifyListeners();
        }
      });
    }
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
