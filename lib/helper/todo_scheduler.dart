import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import 'notifications_helper.dart';
import '../models/todo_model.dart';

const String todoTaskName = 'habitTask';
const String tagTaskName = 'tagTask';

@pragma('vm:entry-point')
void todoWorkmanagerDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    DartPluginRegistrant.ensureInitialized();
    await NotificationsHelper.initialize();

    final taskId = inputData?['taskId']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();
    final tagName = inputData?['tag']?.toString() ?? 'Habit';
    final title = inputData?['title']?.toString() ?? 'Unknown Todo';
    final description = inputData?['description']?.toString() ?? '';
    final notificationBody = description.isNotEmpty ? description : title;
    if (task == tagTaskName) {
      print('Workmanager tag callback started for $tagName');
      await NotificationsHelper.showNotification(
        notificationId: taskId.hashCode,
        title: 'New $tagName Quote',
        body: 'Your scheduled quote reminder is ready.',
      );
      print('Notification shown for tag $tagName');
      debugPrint('Tag task triggered for $tagName');
      return Future.value(true);
    }

    print('Workmanager callback started for $title');
    await NotificationsHelper.showNotification(
      notificationId: taskId.hashCode,
      title: 'New $tagName Quote',
      body: notificationBody,
    );
    print('Notification shown for $title');
    debugPrint('Task triggered for $title');
    return Future.value(true);
  });
}

String _taskUniqueName(String taskId) => 'todo_$taskId';

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

Future<void> scheduleTask({
  required String taskId,
  required Todo todo,
}) async {
  final scheduledTime = todo.scheduledTime;
  final uniqueName = _taskUniqueName(taskId);

  await Workmanager().cancelByUniqueName(uniqueName);

  if (scheduledTime == null || scheduledTime.isEmpty) {
    return;
  }

  await Workmanager().registerOneOffTask(
    uniqueName,
    todoTaskName,
    initialDelay: _delayUntilNextRun(scheduledTime),
    inputData: {
      'taskId': taskId,
      'title': todo.title,
      'description': todo.description,
      'tagName': todo.tags.isNotEmpty ? todo.tags.first : 'Habit',
      'scheduledTime': scheduledTime,
    },
  );
}

Future<void> cancelTask(String taskId) async {
  await Workmanager().cancelByUniqueName(_taskUniqueName(taskId));
}

Future<void> scheduleTagTask(String tagName, String time) async {
  final taskId = 'tag_$tagName';

  await Workmanager().cancelByUniqueName(taskId);
  await Workmanager().registerOneOffTask(
    taskId,
    tagTaskName,
    initialDelay: _delayUntilNextRun(time),
    inputData: {
      'taskId': taskId,
      'tag': tagName,
      'scheduledTime': time,
    },
  );
}
