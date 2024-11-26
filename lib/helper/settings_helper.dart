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

import 'package:shared_preferences/shared_preferences.dart';

class SettingsHelper {
  static const String apiQuotesKey = 'apiQuotesEnabled';
  static const String prefsFileName = 'quote_prefs';

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
}

