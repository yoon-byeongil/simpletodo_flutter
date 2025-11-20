class Todo {
  String title;
  DateTime dueDateTime;
  DateTime? reminderTime;
  bool isDone;

  Todo({
    required this.title,
    required this.dueDateTime,
    this.reminderTime,
    this.isDone = false,
  });

  // 데이터를 저장하기 위해 JSON(Map) 형태로 변환
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'dueDateTime': dueDateTime.toIso8601String(),
      'reminderTime': reminderTime?.toIso8601String(), // null이면 null 저장
      'isDone': isDone,
    };
  }

  // 저장된 데이터를 다시 객체로 변환
  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      title: json['title'],
      dueDateTime: DateTime.parse(json['dueDateTime']),
      reminderTime: json['reminderTime'] != null
          ? DateTime.parse(json['reminderTime'])
          : null,
      isDone: json['isDone'],
    );
  }
}