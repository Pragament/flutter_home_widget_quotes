import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import 'notifications_helper.dart';
import '../models/todo_model.dart';

const String todoTaskName = 'todoScheduledTask';

@pragma('vm:entry-point')
void todoWorkmanagerDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    DartPluginRegistrant.ensureInitialized();
    await NotificationsHelper.initialize();

    final title = inputData?['title']?.toString() ?? 'Unknown Todo';
    print('Workmanager callback started for $title');
    await NotificationsHelper.showNotification(
      'New Habit Reminder',
      title,
    );
    print('Notification shown for $title');
    debugPrint('Task triggered for $title');
    return Future.value(true);
  });
}

String _taskUniqueName(Todo todo) => 'todo_${todo.title}';

Duration _delayUntilNextRun(String scheduledTime) {
  final parts = scheduledTime.split(':');
  final hour = int.tryParse(parts[0]) ?? 0;
  final minute = int.tryParse(parts[1]) ?? 0;

  final now = DateTime.now();
  var scheduledDateTime = DateTime(
    now.year,
    now.month,
    now.day,
    hour,
    minute,
  );

  if (!scheduledDateTime.isAfter(now)) {
    scheduledDateTime = scheduledDateTime.add(const Duration(days: 1));
  }

  return scheduledDateTime.difference(now);
}

Future<void> scheduleTask(Todo todo) async {
  final scheduledTime = todo.scheduledTime;
  final uniqueName = _taskUniqueName(todo);

  await Workmanager().cancelByUniqueName(uniqueName);

  if (scheduledTime == null || scheduledTime.isEmpty) {
    return;
  }

  await Workmanager().registerOneOffTask(
    uniqueName,
    todoTaskName,
    initialDelay: _delayUntilNextRun(scheduledTime),
    inputData: {
      'title': todo.title,
      'scheduledTime': scheduledTime,
    },
  );
}
