import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../model/todo_model.dart';
import '../service/notification_service.dart';

// [역할] 앱의 핵심 비즈니스 로직(CRUD, 알림 제어, 데이터 저장)을 담당하는 클래스
// ChangeNotifier를 상속받아, 데이터가 변경될 때마다 View에게 "다시 그려라"고 알림(notifyListeners)
class TodoViewModel extends ChangeNotifier {
  // 실제 할 일 목록을 담는 리스트 (외부에서 직접 수정 불가하도록 private _todos 사용)
  List<Todo> _todos = [];
  List<Todo> get todos => _todos; // 읽기 전용 접근자(Getter)

  // 알림 기능을 수행하는 서비스 객체
  final NotificationService _notificationService = NotificationService();

  TodoViewModel() {
    _loadTodos(); // 앱 시작 시 저장된 데이터 불러오기
  }

  /// 시간을 5분 단위로 스냅(올림) 처리하는 함수
  /// (예: 13:42 -> 13:45) - UX 개선을 위해 사용
  DateTime normalizeToFiveMinutes(DateTime time) {
    int minute = time.minute;
    int remainder = minute % 5;
    int add = (remainder == 0) ? 0 : (5 - remainder);
    return time.add(Duration(minutes: add)).copyWith(second: 0, millisecond: 0);
  }

  /// 기존 날짜(Year/Month/Day)만 새로운 날짜로 교체 (시간은 유지)
  DateTime applyNewDate(DateTime oldTime, DateTime newDate) {
    return DateTime(newDate.year, newDate.month, newDate.day, oldTime.hour, oldTime.minute);
  }

  /// 기존 시간(Hour/Minute)만 새로운 시간으로 교체 (날짜는 유지)
  DateTime applyNewTime(DateTime oldTime, DateTime newTime) {
    return DateTime(oldTime.year, oldTime.month, oldTime.day, newTime.hour, newTime.minute);
  }

  // ------------------------------------------------------------------
  // [권한] 안드로이드 알람 권한 관리
  // ------------------------------------------------------------------

  /// '정확한 알람(Schedule Exact Alarm)' 권한이 거부되었는지 확인
  Future<bool> checkPermissionStatus() async {
    final status = await Permission.scheduleExactAlarm.status;
    return status.isDenied;
  }

  /// 권한 요청 팝업(또는 설정창 이동) 실행
  Future<void> requestPermission() async {
    await Permission.scheduleExactAlarm.request();
  }

  // ------------------------------------------------------------------
  // [기능] 할 일 관리 (CRUD + 알림 연동)
  // ------------------------------------------------------------------

  // 1. 추가 (Create)
  void addTodo(String title, DateTime due, DateTime? reminder, bool isGlobalOn) {
    // ID를 현재 시간(밀리초)으로 생성하여 중복 방지
    int newId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final newTodo = Todo(id: newId, title: title, dueDateTime: due, reminderTime: reminder);
    _todos.add(newTodo);

    // 알림이 설정되어 있고, 전역 설정이 켜져 있다면 스케줄링
    if (reminder != null && isGlobalOn) {
      if (reminder.isBefore(DateTime.now())) {
        _notificationService.showImmediateNotification(id: newId, title: title); // 과거면 즉시
      } else {
        _notificationService.scheduleNotification(id: newId, title: title, scheduledTime: reminder); // 미래면 예약
      }
    }
    _sortTodos(); // 추가 후 정렬
    _saveTodos(); // 로컬 저장
    notifyListeners(); // 화면 갱신
  }

  // 2. 수정 (Update)
  void editTodo(int index, String newTitle, DateTime newDue, DateTime? newReminder, bool isGlobalOn) {
    if (index >= _todos.length) return;
    final todo = _todos[index];

    // 내용 업데이트
    todo.title = newTitle;
    todo.dueDateTime = newDue;
    todo.reminderTime = newReminder;

    // 기존 알림 취소 후 새로 등록
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

  // 3. 고정 (Pin) 토글 - [BM] 수익화 모델 연결됨
  // 반환값(bool): 성공(true) 또는 유료 제한 걸림(false)
  bool togglePin(int index, bool isPremium, {bool forceReplace = false}) {
    if (index >= _todos.length) return false;
    final targetTodo = _todos[index];

    // 해제는 제한 없음
    if (targetTodo.isPinned) {
      targetTodo.isPinned = false;
      _sortTodos();
      _saveTodos();
      notifyListeners();
      return true;
    }

    // [옵션] 강제 교체 모드 (다이얼로그에서 '교체' 선택 시)
    if (forceReplace) {
      for (var todo in _todos) {
        todo.isPinned = false;
      } // 기존 핀 모두 해제
      targetTodo.isPinned = true;
      _sortTodos();
      _saveTodos();
      notifyListeners();
      return true;
    }

    // [BM 핵심] 무료 유저는 핀 개수 제한 (1개)
    int pinnedCount = _todos.where((t) => t.isPinned).length;
    if (!isPremium && pinnedCount >= 1) {
      return false; // View에서 이 값을 보고 '결제 유도 팝업'을 띄움
    }

    targetTodo.isPinned = true;
    _sortTodos();
    _saveTodos();
    notifyListeners();
    return true;
  }

  // 4. 완료 (Done) 토글
  void toggleDone(int index, bool isAutoDeleteOn) {
    if (index >= _todos.length) return;
    _todos[index].isDone = !_todos[index].isDone;

    // 완료 시 알림은 취소하는 것이 일반적
    if (_todos[index].isDone) {
      _notificationService.cancelNotification(_todos[index].id);
    }
    _saveTodos();
    notifyListeners();

    // [옵션] 자동 삭제 기능이 켜져 있으면 0.1초 뒤 삭제 (애니메이션 효과)
    if (isAutoDeleteOn && _todos[index].isDone) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (index < _todos.length && _todos[index].isDone) {
          deleteTodo(index);
        }
      });
    }
  }

  // 5. 삭제 (Delete)
  void deleteTodo(int index) {
    if (index >= _todos.length) return;
    // 데이터 삭제 전 알림부터 취소해야 꼬이지 않음
    _notificationService.cancelNotification(_todos[index].id);
    _todos.removeAt(index);
    _saveTodos();
    notifyListeners();
  }

  // 6. 지난 일정 일괄 삭제 (설정 화면 기능)
  void deleteOverdueTodos() {
    final now = DateTime.now();
    // 삭제될 항목들의 알림 취소
    for (var todo in _todos) {
      if (todo.dueDateTime.isBefore(now)) {
        _notificationService.cancelNotification(todo.id);
      }
    }
    _todos.removeWhere((todo) => todo.dueDateTime.isBefore(now));
    _saveTodos();
    notifyListeners();
  }

  // 7. 전체 초기화 (데이터 리셋)
  void clearAllTodos() {
    _todos.clear();
    _notificationService.cancelAll(); // 모든 알림 취소
    _saveTodos();
    notifyListeners();
  }

  // ------------------------------------------------------------------
  // [설정 연동] 알림 일괄 제어
  // ------------------------------------------------------------------

  void cancelAllReminders() {
    _notificationService.cancelAll();
    notifyListeners();
  }

  // 앱 설정에서 알림을 켰을 때, 기존의 미래 알림들을 다시 예약 복구
  void restoreAllReminders() {
    final now = DateTime.now();
    for (var todo in _todos) {
      if (!todo.isDone && todo.reminderTime != null && todo.reminderTime!.isAfter(now)) {
        _notificationService.scheduleNotification(id: todo.id, title: todo.title, scheduledTime: todo.reminderTime!);
      }
    }
    notifyListeners();
  }

  // 리스트 아이콘 클릭해서 알림 시간만 수정할 때
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

  // 정렬 로직: 1순위 핀 고정, 2순위 시간순
  void _sortTodos() {
    _todos.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1; // a가 핀이면 위로
      if (!a.isPinned && b.isPinned) return 1; // b가 핀이면 위로
      return a.dueDateTime.compareTo(b.dueDateTime); // 시간순
    });
  }

  // ------------------------------------------------------------------
  // [데이터 저장소] Shared Preferences (나중에 Repository로 분리 가능)
  // ------------------------------------------------------------------

  Future<void> _saveTodos() async {
    final prefs = await SharedPreferences.getInstance();
    // 객체 리스트 -> JSON 문자열로 변환하여 저장
    final String encodedData = jsonEncode(_todos.map((e) => e.toJson()).toList());
    await prefs.setString('todo_list', encodedData);
  }

  Future<void> _loadTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString('todo_list');
    if (jsonString != null) {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      // JSON 문자열 -> 객체 리스트로 복원
      _todos = jsonList.map((e) => Todo.fromJson(e)).toList();
      notifyListeners();
    }
  }
}
