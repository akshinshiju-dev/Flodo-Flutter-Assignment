// Task data model and TaskStatus enum

enum TaskStatus {
  todo,
  inProgress,
  done;

  String get label {
    switch (this) {
      case TaskStatus.todo:
        return 'To-Do';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.done:
        return 'Done';
    }
  }

  static TaskStatus fromString(String value) {
    switch (value) {
      case 'inProgress':
        return TaskStatus.inProgress;
      case 'done':
        return TaskStatus.done;
      default:
        return TaskStatus.todo;
    }
  }
}

class Task {
  final int? id;
  final String title;
  final String description;
  final DateTime dueDate;
  final TaskStatus status;
  final int? blockedById; // FK to another task's id (nullable)
  final int sortOrder;    // for future drag-and-drop ordering

  const Task({
    this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    this.status = TaskStatus.todo,
    this.blockedById,
    this.sortOrder = 0,
  });

  Task copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? dueDate,
    TaskStatus? status,
    Object? blockedById = _sentinel,
    int? sortOrder,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      blockedById: blockedById == _sentinel
          ? this.blockedById
          : blockedById as int?,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'due_date': dueDate.toIso8601String(),
      'status': status.name,
      'blocked_by_id': blockedById,
      'sort_order': sortOrder,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      dueDate: DateTime.parse(map['due_date'] as String),
      status: TaskStatus.fromString(map['status'] as String),
      blockedById: map['blocked_by_id'] as int?,
      sortOrder: map['sort_order'] as int? ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Task && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

// Sentinel object for nullable copyWith fields
const Object _sentinel = Object();
