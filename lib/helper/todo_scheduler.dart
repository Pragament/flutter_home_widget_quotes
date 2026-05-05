import 'dart:io';
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_wallpaper_manager/flutter_wallpaper_manager.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../models/tag_settings_model.dart';
import '../models/todo_model.dart';
import 'todo_box_helper.dart';
import 'notifications_helper.dart';

const String tagTaskName = 'tagTask';
const String _todoScheduleRegistryKey = 'todoScheduleRegistryV1';
const String _tagLastExecutionPrefix = 'tagTaskLastExecutionV1_';

String _normalizeTagKey(String tagName) => tagName.trim().toLowerCase();

@pragma('vm:entry-point')
void todoWorkmanagerDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      DartPluginRegistrant.ensureInitialized();
      await NotificationsHelper.initialize();
      final tagSettingsBox = await _getTagSettingsBox();
      final tagSettingsCache = <String, TagSettingsModel>{};

      final taskId =
          inputData?['taskId']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString();
      final tagName =
          inputData?['tagId']?.toString() ??
          inputData?['tag']?.toString() ??
          'Habit';
      if (task == tagTaskName) {
        final settings = _effectiveTagSettings(
          tagSettingsBox,
          tagName,
          cache: tagSettingsCache,
        );
        final scheduledHour =
            _parseInt(inputData?['scheduledHour']) ??
            int.tryParse((settings.scheduledTime ?? '').split(':').first);
        final scheduledMinute =
            _parseInt(inputData?['scheduledMinute']) ??
            (() {
              final parts = (settings.scheduledTime ?? '').split(':');
              if (parts.length != 2) return null;
              return int.tryParse(parts[1]);
            })();

        final notificationEnabled =
            _parseBool(inputData?['notificationEnabled']) ??
            settings.notificationEnabled;
        final wallpaperEnabled =
            _parseBool(inputData?['wallpaperEnabled']) ??
            settings.wallpaperEnabled;

        if (scheduledHour == null ||
            scheduledMinute == null ||
            !_isWithinValidQuarterHourWindow(
              scheduledHour: scheduledHour,
              scheduledMinute: scheduledMinute,
            )) {
          debugPrint('Skipping tag task for $tagName due to non-matching time window');
          return Future.value(true);
        }

        final alreadyExecutedToday = await _hasTagExecutedToday(tagName);
        if (alreadyExecutedToday) {
          debugPrint('Skipping tag task for $tagName because it already ran today');
          return Future.value(true);
        }

        print('Workmanager tag callback started for $tagName');
        if (notificationEnabled) {
          await NotificationsHelper.showNotification(
            notificationId: taskId.hashCode,
            title: 'New $tagName Quote',
            body: 'Your scheduled quote reminder is ready.',
          );
          print('Notification shown for tag $tagName');
        } else {
          debugPrint('Skipping tag notification for $tagName because notification is disabled');
        }

        if (wallpaperEnabled) {
          await _applyScheduledWallpaperForTag(tagName);
        }
        await _markTagExecutedToday(tagName);

        debugPrint('Tag task triggered for $tagName');
        return Future.value(true);
      }

      debugPrint('Ignoring legacy non-tag task `$task` to keep scheduling periodic-per-tag only');
      return Future.value(true);
    } catch (error, stackTrace) {
      debugPrint('Workmanager background task failed: $error');
      debugPrint(stackTrace.toString());
      return Future.value(true);
    }
  });
}

bool _isWithinValidQuarterHourWindow({
  required int scheduledHour,
  required int scheduledMinute,
}) {
  if (scheduledHour < 0 || scheduledHour > 23 || scheduledMinute < 0 || scheduledMinute > 59) {
    return false;
  }
  final now = DateTime.now();
  return now.hour == scheduledHour && (now.minute ~/ 15) == (scheduledMinute ~/ 15);
}

Future<bool> _hasTagExecutedToday(String tagName) async {
  final prefs = await SharedPreferences.getInstance();
  final lastDate = prefs.getString('$_tagLastExecutionPrefix${_normalizeTagKey(tagName)}');
  final now = DateTime.now();
  final today = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  return lastDate == today;
}

Future<void> _markTagExecutedToday(String tagName) async {
  final prefs = await SharedPreferences.getInstance();
  final now = DateTime.now();
  final today = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  await prefs.setString('$_tagLastExecutionPrefix${_normalizeTagKey(tagName)}', today);
}

int? _parseInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '');
}

bool? _parseBool(dynamic value) {
  if (value is bool) return value;
  final raw = value?.toString().toLowerCase();
  if (raw == 'true') return true;
  if (raw == 'false') return false;
  return null;
}

String _taskUniqueName(String todoId, String scheduledTime) =>
    'todo_${todoId}_${scheduledTime.replaceAll(':', '')}';

String _legacyTaskUniqueName(String todoId) => 'todo_$todoId';

String? _normalizeTimeString(String? scheduledTime) {
  if (scheduledTime == null || !scheduledTime.contains(':')) {
    return null;
  }

  final parts = scheduledTime.split(':');
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
  return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

Future<Box<TagSettingsModel>> _getTagSettingsBox() async {
  if (Hive.isBoxOpen('tagSettingsBox')) {
    return Hive.box<TagSettingsModel>('tagSettingsBox');
  }

  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(TagSettingsModelAdapter());
  }

  try {
    return await Hive.openBox<TagSettingsModel>('tagSettingsBox');
  } catch (_) {
    final directory = await getApplicationDocumentsDirectory();
    Hive.init(directory.path);
    return await Hive.openBox<TagSettingsModel>('tagSettingsBox');
  }
}

TagSettingsModel _effectiveTagSettings(
  Box<TagSettingsModel> box,
  String tagName,
  {Map<String, TagSettingsModel>? cache}
) {
  final normalizedKey = _normalizeTagKey(tagName);

  if (cache != null) {
    if (cache.isEmpty) {
      for (final settings in box.values) {
        cache[_normalizeTagKey(settings.tagName)] = settings;
      }
    }
    return cache[normalizedKey] ?? TagSettingsModel(tagName: tagName.trim());
  }

  for (final settings in box.values) {
    if (_normalizeTagKey(settings.tagName) == normalizedKey) {
      return settings;
    }
  }
  return TagSettingsModel(tagName: tagName.trim());
}

Future<void> _applyScheduledWallpaperForTag(String tagName) async {
  try {
    final imageFile = await _generateWallpaperImageForTag(tagName);
    await WallpaperManager.setWallpaperFromFile(
      imageFile.path,
      WallpaperManager.HOME_SCREEN,
    );
  } catch (error) {
    debugPrint('Scheduled wallpaper update failed for tag $tagName: $error');
  }
}

Future<File> _generateWallpaperImageForTag(String tagName) async {
  const double width = 1080;
  const double height = 1920;
  final timestamp = DateTime.now();
  final wallpaperText =
      'Tag: ${tagName.trim().isEmpty ? 'General' : tagName.trim()}\n${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(
    recorder,
    const Rect.fromLTWH(0, 0, width, height),
  );

  canvas.drawRect(
    const Rect.fromLTWH(0, 0, width, height),
    Paint()..color = Colors.white,
  );

  final textPainter = TextPainter(
    textAlign: TextAlign.center,
    textDirection: TextDirection.ltr,
    text: TextSpan(
      text: wallpaperText,
      style: const TextStyle(
        fontSize: 54,
        color: Colors.black,
        fontWeight: FontWeight.w600,
      ),
    ),
  )..layout(maxWidth: width * 0.82);

  final offset = Offset(
    (width - textPainter.width) / 2,
    (height - textPainter.height) / 2,
  );
  textPainter.paint(canvas, offset);

  final picture = recorder.endRecording();
  final image = await picture.toImage(width.toInt(), height.toInt());
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  final bytes = byteData!.buffer.asUint8List();

  final directory = await getTemporaryDirectory();
  final file = File('${directory.path}/scheduled_tag_wallpaper.png');
  await file.writeAsBytes(bytes, flush: true);
  return file;
}

Future<Map<String, String>> _readScheduleRegistry() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getStringList(_todoScheduleRegistryKey) ?? <String>[];
  final entries = <String, String>{};
  for (final item in raw) {
    final splitIndex = item.indexOf('=');
    if (splitIndex <= 0 || splitIndex >= item.length - 1) {
      continue;
    }
    final todoId = item.substring(0, splitIndex);
    final uniqueName = item.substring(splitIndex + 1);
    entries[todoId] = uniqueName;
  }
  return entries;
}

Future<void> _writeScheduleRegistry(Map<String, String> registry) async {
  final prefs = await SharedPreferences.getInstance();
  final list = registry.entries.map((entry) => '${entry.key}=${entry.value}').toList();
  await prefs.setStringList(_todoScheduleRegistryKey, list);
}

Future<void> syncTodoSchedules() async {
  final todoBox = await TodoBoxHelper.getTodoBox();
  final registry = await _readScheduleRegistry();
  final liveTodoIds = <String>{};

  for (int index = 0; index < todoBox.length; index++) {
    final todo = todoBox.getAt(index);
    if (todo == null) {
      continue;
    }

    final todoId = todoBox.keyAt(index).toString();
    liveTodoIds.add(todoId);
    await Workmanager().cancelByUniqueName(_legacyTaskUniqueName(todoId));
    final normalizedTime = _normalizeTimeString(todo.scheduledTime);
    if (normalizedTime != null) {
      await Workmanager().cancelByUniqueName(_taskUniqueName(todoId, normalizedTime));
    }
    final previousUniqueName = registry.remove(todoId);
    if (previousUniqueName != null) {
      await Workmanager().cancelByUniqueName(previousUniqueName);
    }
  }

  final staleTodoIds = registry.keys.where((id) => !liveTodoIds.contains(id)).toList();
  for (final staleTodoId in staleTodoIds) {
    final staleUniqueName = registry[staleTodoId];
    if (staleUniqueName != null) {
      await Workmanager().cancelByUniqueName(staleUniqueName);
    }
    registry.remove(staleTodoId);
  }

  if (registry.isNotEmpty) {
    for (final uniqueName in registry.values) {
      await Workmanager().cancelByUniqueName(uniqueName);
    }
  }
  await _writeScheduleRegistry(<String, String>{});
}

Future<void> scheduleTagTask(String tagName, String _) async {
  await syncTagSchedules(onlyTagName: tagName);
}

Future<void> syncTagSchedules({String? onlyTagName}) async {
  final tagSettingsBox = await _getTagSettingsBox();

  if (onlyTagName != null) {
    await _syncSingleTagSchedule(
      tagName: onlyTagName,
      settings: _effectiveTagSettings(tagSettingsBox, onlyTagName),
    );
    return;
  }

  for (final settings in tagSettingsBox.values) {
    await _syncSingleTagSchedule(
      tagName: settings.tagName,
      settings: settings,
    );
  }
}

Future<void> _syncSingleTagSchedule({
  required String tagName,
  required TagSettingsModel settings,
}) async {
  try {
    final uniqueName = _tagTaskUniqueName(tagName);
    final legacyUniqueName = _legacyTagTaskUniqueName(tagName);
    final normalizedTime = _normalizeTimeString(settings.scheduledTime);
    final canSchedule = settings.notificationEnabled || settings.wallpaperEnabled;

    await Workmanager().cancelByUniqueName(uniqueName);
    await Workmanager().cancelByUniqueName(legacyUniqueName);

    if (normalizedTime == null || !canSchedule) {
      return;
    }

    final parts = normalizedTime.split(':');
    final scheduledHour = int.parse(parts[0]);
    final scheduledMinute = int.parse(parts[1]);

    await Workmanager().registerPeriodicTask(
      uniqueName,
      tagTaskName,
      frequency: const Duration(minutes: 15),
      inputData: {
        'taskId': uniqueName,
        'tagId': tagName,
        'tag': tagName,
        'scheduledHour': scheduledHour,
        'scheduledMinute': scheduledMinute,
        'notificationEnabled': settings.notificationEnabled,
        'wallpaperEnabled': settings.wallpaperEnabled,
      },
    );
  } catch (error, stackTrace) {
    debugPrint('Failed syncing periodic tag task for $tagName: $error');
    debugPrint(stackTrace.toString());
  }
}

String _tagTaskUniqueName(String tagName) => 'tag_${tagName}_task';
String _legacyTagTaskUniqueName(String tagName) => 'tag_$tagName';
