import 'package:uuid/uuid.dart';

class TodoModel {
  final String id;
  String title;
  bool isDone;
  bool isRecurring;
  DateTime createdAt;
  DateTime? completedAt;
  DateTime? lastCompletedAt;
  String? description;
  String? category;
  List<String>? tags;
  List<String>? checklist;
  Map<String, dynamic>? schedule;

  TodoModel({
    String? id,
    required this.title,
    this.isDone = false,
    this.isRecurring = false,
    DateTime? createdAt,
    this.completedAt,
    this.lastCompletedAt,
    this.description,
    this.category,
    this.tags,
    this.checklist,
    this.schedule,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  factory TodoModel.fromMap(Map<String, dynamic> map) {
    return TodoModel(
      id: map['id'] as String,
      title: map['title'] as String,
      isDone: map['isDone'] as bool? ?? false,
      isRecurring: map['isRecurring'] as bool? ?? false,
      createdAt: DateTime.parse(map['createdAt'] as String),
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'] as String)
          : null,
      lastCompletedAt: map['lastCompletedAt'] != null
          ? DateTime.parse(map['lastCompletedAt'] as String)
          : null,
      description: map['description'] as String?,
      category: map['category'] as String?,
      tags: map['tags'] != null ? List<String>.from(map['tags']) : null,
      checklist: map['checklist'] != null ? List<String>.from(map['checklist']) : null,
      schedule: map['schedule'] != null ? Map<String, dynamic>.from(map['schedule']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'isDone': isDone,
      'isRecurring': isRecurring,
      'createdAt': createdAt.toIso8601String(),
      if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
      if (lastCompletedAt != null)
        'lastCompletedAt': lastCompletedAt!.toIso8601String(),
      if (description != null) 'description': description,
      if (category != null) 'category': category,
      if (tags != null) 'tags': tags,
      if (checklist != null) 'checklist': checklist,
      if (schedule != null) 'schedule': schedule,
    };
  }
}

