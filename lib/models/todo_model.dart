import 'package:flutter/material.dart';
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

  @HiveField(6)
  bool isRecurring;

  @HiveField(7)
  TimeOfDay? scheduleTime;

  @HiveField(8)
  String repeatType;

  @HiveField(9)
  String? lastCompletedDate;

  Todo({
    required this.title,
    required this.description,
    required this.category,
    required this.tags,
    this.isCompleted = false,
    this.scheduledTime,
    this.isRecurring = false,
    this.scheduleTime,
    this.repeatType = 'daily',
    this.lastCompletedDate,
  });
}
