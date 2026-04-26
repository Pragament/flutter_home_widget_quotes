import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:home_widget/home_widget.dart';

import '../models/todo_model.dart';

const String _habitTitleKey = 'habit_widget_title';
const String _habitTimeKey = 'habit_widget_time';

Future<Box<Todo>> _getTodoBox() async {
  try {
    if (Hive.isBoxOpen('todos')) {
      return Hive.box<Todo>('todos');
    }
    return Hive.openBox<Todo>('todos');
  } catch (_) {
    rethrow;
  }
}

String _todayDateKey() {
  final now = DateTime.now();
  final year = now.year.toString().padLeft(4, '0');
  final month = now.month.toString().padLeft(2, '0');
  final day = now.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

TimeOfDay? _parseTimeString(String? value) {
  if (value == null || !value.contains(':')) {
    return null;
  }
  final parts = value.split(':');
  if (parts.length != 2) {
    return null;
  }
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) {
    return null;
  }
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
    return null;
  }
  return TimeOfDay(hour: hour, minute: minute);
}

TimeOfDay? _resolveScheduleTime(Todo todo) {
  return todo.scheduleTime ?? _parseTimeString(todo.scheduledTime);
}

bool _isCompletedToday(Todo todo) {
  return todo.lastCompletedDate == _todayDateKey();
}

DateTime _nextOccurrence(TimeOfDay time) {
  final now = DateTime.now();
  DateTime when = DateTime(
    now.year,
    now.month,
    now.day,
    time.hour,
    time.minute,
  );
  if (!when.isAfter(now)) {
    when = when.add(const Duration(days: 1));
  }
  return when;
}

String _formatTime(TimeOfDay time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

Future<Todo?> getNextPendingHabit() async {
  try {
    final todoBox = await _getTodoBox();
    Todo? bestTodo;
    DateTime? bestWhen;

    for (final todo in todoBox.values) {
      if (!todo.isRecurring) {
        continue;
      }
      if (_isCompletedToday(todo)) {
        continue;
      }
      final time = _resolveScheduleTime(todo);
      if (time == null) {
        continue;
      }

      final when = _nextOccurrence(time);
      if (bestWhen == null || when.isBefore(bestWhen)) {
        bestWhen = when;
        bestTodo = todo;
      }
    }

    return bestTodo;
  } catch (_) {
    return null;
  }
}

Future<void> refreshHabitWidget() async {
  try {
    await HomeWidget.setAppGroupId('group.es.antonborri.homeWidgetCounter');
    final nextHabit = await getNextPendingHabit();

    await HomeWidget.saveWidgetData(
      _habitTitleKey,
      nextHabit == null
          ? 'No pending habits'
          : (nextHabit.title.isEmpty ? 'Untitled Habit' : nextHabit.title),
    );
    final time = nextHabit == null ? null : _resolveScheduleTime(nextHabit);
    await HomeWidget.saveWidgetData(_habitTimeKey, time == null ? '' : _formatTime(time));

    if (Platform.isAndroid) {
      await HomeWidget.updateWidget(androidName: 'HabitWidgetProvider');
    }
  } catch (_) {
    // Keep widget refresh failures non-fatal.
  }
}
