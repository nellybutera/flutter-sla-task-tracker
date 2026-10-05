enum Priority { low, medium, high }

class Task {
  final String id;
  final String title;
  final String description;
  final String assigneeId;
  final Priority priority;
  final DateTime deadline;
  final bool isCompleted;
  final DateTime createdAt;

  const Task({
    required this.id,
    required this.title,
    this.description = '',
    required this.assigneeId,
    required this.priority,
    required this.deadline,
    this.isCompleted = false,
    required this.createdAt,
  });

  Task copyWith({
    String? title,
    String? description,
    String? assigneeId,
    Priority? priority,
    DateTime? deadline,
    bool? isCompleted,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      assigneeId: assigneeId ?? this.assigneeId,
      priority: priority ?? this.priority,
      deadline: deadline ?? this.deadline,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'assigneeId': assigneeId,
    'priority': priority.name,
    'deadline': deadline.toIso8601String(),
    'isCompleted': isCompleted,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'] as String,
    title: json['title'] as String,
    description: (json['description'] as String?) ?? '',
    assigneeId: json['assigneeId'] as String,
    priority: Priority.values.byName(json['priority'] as String),
    deadline: DateTime.parse(json['deadline'] as String),
    isCompleted: (json['isCompleted'] as bool?) ?? false,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
