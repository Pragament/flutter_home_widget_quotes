// import 'package:shared_preferences/shared_preferences.dart';
//
// class SettingsHelper {
//   static const String apiQuotesKey = 'apiQuotesEnabled';
//
//   static Future<bool> isApiQuotesEnabled() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getBool(apiQuotesKey) ?? true; // Default to true
//   }
//
//   static Future<void> setApiQuotesEnabled(bool isEnabled) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setBool(apiQuotesKey, isEnabled);
//   }
// }
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tag_model.dart';

class SettingsHelper {
  static const String apiQuotesKey = 'apiQuotesEnabled';
  static const String prefsFileName = 'quote_prefs';
  static const String tagsKey = 'savedTags';
  static const String firstLaunchKey = 'firstLaunch';
  static const String scheduleEnabledKey = 'scheduleEnabled';
  static const String scheduleTimeKey = 'scheduleTime';
  static const String enableNotificationsKey = 'enableNotifications';
  static const String enableWallpaperKey = 'enableWallpaper';

  /// Get SharedPreferences instance
  static Future<SharedPreferences> _getSharedPreferences() async {
    return await SharedPreferences.getInstance();
  }

  /// Check if it's the first launch of the app
  static Future<bool> isFirstLaunch() async {
    final prefs = await _getSharedPreferences();
    bool firstLaunch = prefs.getBool(firstLaunchKey) ?? true;

    if (firstLaunch) {
      await prefs.setBool(firstLaunchKey, false);
    }
    return firstLaunch;
  }

  /// Check if API quotes are enabled (default: true)
  static Future<bool> isApiQuotesEnabled() async {
    final prefs = await _getSharedPreferences();
    return prefs.getBool(apiQuotesKey) ?? true;
  }

  /// Enable or disable API quotes
  static Future<void> setApiQuotesEnabled(bool isEnabled) async {
    final prefs = await _getSharedPreferences();
    await prefs.setBool(apiQuotesKey, isEnabled);
  }

  /// Save a list of tags to SharedPreferences
  static Future<void> saveTags(List<TagModel> tags) async {
    final prefs = await _getSharedPreferences();
    final String tagsJsonString =
        json.encode(tags.map((tag) => tag.toMap()).toList());
    print('Tags are: $tagsJsonString');
    await prefs.setString(tagsKey, tagsJsonString);
  }

  /// Check if schedule is enabled
  static Future<bool> isScheduleEnabled() async {
    final prefs = await _getSharedPreferences();
    return prefs.getBool(scheduleEnabledKey) ?? false;
  }

  /// Enable or disable schedule
  static Future<void> setScheduleEnabled(bool isEnabled) async {
    final prefs = await _getSharedPreferences();
    await prefs.setBool(scheduleEnabledKey, isEnabled);
  }

  /// Get schedule time (hour and minute)
  static Future<TimeOfDay?> getScheduleTime() async {
    final prefs = await _getSharedPreferences();
    final timeString = prefs.getString(scheduleTimeKey);
    if (timeString != null) {
      final parts = timeString.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }
    return null;
  }

  /// Set schedule time
  static Future<void> setScheduleTime(TimeOfDay time) async {
    final prefs = await _getSharedPreferences();
    final timeString = '${time.hour}:${time.minute}';
    await prefs.setString(scheduleTimeKey, timeString);
  }

  /// Check if notifications are enabled
  static Future<bool> isNotificationsEnabled() async {
    final prefs = await _getSharedPreferences();
    return prefs.getBool(enableNotificationsKey) ?? false;
  }

  /// Enable or disable notifications
  static Future<void> setNotificationsEnabled(bool isEnabled) async {
    final prefs = await _getSharedPreferences();
    await prefs.setBool(enableNotificationsKey, isEnabled);
  }

  /// Check if wallpaper change is enabled
  static Future<bool> isWallpaperEnabled() async {
    final prefs = await _getSharedPreferences();
    return prefs.getBool(enableWallpaperKey) ?? false;
  }

  /// Enable or disable wallpaper change
  static Future<void> setWallpaperEnabled(bool isEnabled) async {
    final prefs = await _getSharedPreferences();
    await prefs.setBool(enableWallpaperKey, isEnabled);
  }
}
