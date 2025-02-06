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
    await prefs.setString(tagsKey, tagsJsonString);
  }
}
