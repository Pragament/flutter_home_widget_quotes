import 'package:hive_flutter/hive_flutter.dart';

part 'tag_settings_model.g.dart';

@HiveType(typeId: 3)
class TagSettingsModel {
  @HiveField(0)
  final String tagName;

  @HiveField(1)
  String? scheduledTime;

  @HiveField(2)
  bool notificationEnabled;

  @HiveField(3)
  bool wallpaperEnabled;

  TagSettingsModel({
    required this.tagName,
    this.scheduledTime,
    this.notificationEnabled = false,
    this.wallpaperEnabled = false,
  });
}
