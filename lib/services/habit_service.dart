import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/habit_model.dart';

class HabitService {
  static const String _habitsUrl =
      'https://staticapis.pragament.com/daily/habits.json';

  Future<List<Habit>> fetchHabits() async {
    try {
      final response = await http.get(Uri.parse(_habitsUrl));

      if (response.statusCode != 200) {
        throw Exception('Failed to load habits');
      }

      final decoded = json.decode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Failed to load habits');
      }

      final habitsJson = decoded['habits'];
      if (habitsJson is! List) {
        throw Exception('Failed to load habits');
      }

      return habitsJson
          .whereType<Map<String, dynamic>>()
          .map(Habit.fromJson)
          .toList();
    } catch (_) {
      throw Exception('Failed to load habits');
    }
  }
}
