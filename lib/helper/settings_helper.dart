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

  static Future<SharedPreferences> _getSharedPreferences() async {
    return await SharedPreferences.getInstance();
  }

  static Future<bool> isApiQuotesEnabled() async {
    final prefs = await _getSharedPreferences();
    return prefs.getBool(apiQuotesKey) ?? true; // Default to true
  }

  static Future<void> setApiQuotesEnabled(bool isEnabled) async {
    final prefs = await _getSharedPreferences();
    await prefs.setBool(apiQuotesKey, isEnabled);
  }

  static Future<void> saveTags(List<TagModel> tags) async {
    final prefs = await _getSharedPreferences();
    final String tagsJsonString = json.encode(tags.map((tag) => tag.toMap()).toList());
    print("TAgs are: $tagsJsonString");
    await prefs.setString(tagsKey, tagsJsonString);
  }

}

