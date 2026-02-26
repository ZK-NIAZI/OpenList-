class TaskModel {
  final String id;
  final String title;
  final String? description;
  final bool isCompleted;
  final String priority; // low, medium, high
  final DateTime? dueDate;
  final String? spaceId;
  final String ownerId;
  final String? parentTaskId;
  final int position;
  final DateTime createdAt;
  final DateTime updatedAt;

  TaskModel({
    required this.id,
    required this.title,
    this.description,
    required this.isCompleted,
    required this.priority,
    this.dueDate,
    this.spaceId,
    required this.ownerId,
    this.parentTaskId,
    required this.position,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      isCompleted: json['is_completed'] as bool? ?? false,
      priority: json['priority'] as String? ?? 'medium',
      dueDate: json['due_date'] != null 
          ? DateTime.parse(json['due_date'] as String)
          : null,
      spaceId: json['space_id'] as String?,
      ownerId: json['owner_id'] as String,
      parentTaskId: json['parent_task_id'] as String?,
      position: json['position'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'is_completed': isCompleted,
      'priority': priority,
      'due_date': dueDate?.toIso8601String(),
      'space_id': spaceId,
      'owner_id': ownerId,
      'parent_task_id': parentTaskId,
      'position': position,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
    String? priority,
    DateTime? dueDate,
    String? spaceId,
    String? ownerId,
    String? parentTaskId,
    int? position,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      spaceId: spaceId ?? this.spaceId,
      ownerId: ownerId ?? this.ownerId,
      parentTaskId: parentTaskId ?? this.parentTaskId,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
