class Todo {
  int id; // [추가] 알림 ID로 사용할 고유 번호
  String title;
  DateTime dueDateTime;
  DateTime? reminderTime;
  bool isDone;

  Todo({
    required this.id, // [추가]
    required this.title,
    required this.dueDateTime,
    this.reminderTime,
    this.isDone = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id, // [추가]
      'title': title,
      'dueDateTime': dueDateTime.toIso8601String(),
      'reminderTime': reminderTime?.toIso8601String(),
      'isDone': isDone,
    };
  }

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch, // 없으면 현재시간으로 생성
      title: json['title'],
      dueDateTime: DateTime.parse(json['dueDateTime']),
      reminderTime: json['reminderTime'] != null ? DateTime.parse(json['reminderTime']) : null,
      isDone: json['isDone'],
    );
  }
}
