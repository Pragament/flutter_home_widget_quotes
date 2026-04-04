import 'package:hive_flutter/hive_flutter.dart';

part 'todo_model.g.dart';

@HiveType(typeId: 2)
class Todo {
  @HiveField(0)
  final String title;

  @HiveField(1)
  final String description;

  @HiveField(2)
  final String category;

  @HiveField(3)
  final List<String> tags;

  @HiveField(4)
  bool isCompleted;

  @HiveField(5)
  String? scheduledTime;

  Todo({
    required this.title,
    required this.description,
    required this.category,
    required this.tags,
    this.isCompleted = false,
    this.scheduledTime,
  });
}
