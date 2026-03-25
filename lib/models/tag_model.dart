import 'package:hive_flutter/hive_flutter.dart';

part 'tag_model.g.dart';

@HiveType(typeId: 1)
class TagModel {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? scheduleTime; // HH:MM format

  @HiveField(3)
  bool enableNotifications;

  @HiveField(4)
  bool enableWallpaper;

  TagModel({
    required this.id,
    required this.name,
    this.scheduleTime,
    this.enableNotifications = false,
    this.enableWallpaper = false,
  });

  factory TagModel.fromMap(Map<String, dynamic> json) => TagModel(
        id: json['id'],
        name: json['name'],
        scheduleTime: json['scheduleTime'],
        enableNotifications: json['enableNotifications'] ?? false,
        enableWallpaper: json['enableWallpaper'] ?? false,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        if (scheduleTime != null) 'scheduleTime': scheduleTime,
        'enableNotifications': enableNotifications,
        'enableWallpaper': enableWallpaper,
      };
}
