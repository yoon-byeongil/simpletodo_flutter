class Todo {
  int id;
  String title;
  DateTime dueDateTime;
  DateTime? reminderTime;
  bool isDone;
  bool isPinned;

  Todo({required this.id, required this.title, required this.dueDateTime, this.reminderTime, this.isDone = false, this.isPinned = false});

  Map<String, dynamic> toJson() {
    return {'id': id, 'title': title, 'dueDateTime': dueDateTime.toIso8601String(), 'reminderTime': reminderTime?.toIso8601String(), 'isDone': isDone, 'isPinned': isPinned};
  }

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch,
      title: json['title'],
      dueDateTime: DateTime.parse(json['dueDateTime']),
      reminderTime: json['reminderTime'] != null ? DateTime.parse(json['reminderTime']) : null,
      isDone: json['isDone'],
      isPinned: json['isPinned'] ?? false,
    );
  }
}
