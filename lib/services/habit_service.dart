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
        throw Exception(
          'Failed to load habits. Status code: ${response.statusCode}',
        );
      }

      final decoded = json.decode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Invalid habits response format.');
      }

      final habitsJson = decoded['habits'];
      if (habitsJson is! List) {
        throw Exception('Habits list not found in response.');
      }

      return habitsJson
          .whereType<Map<String, dynamic>>()
          .map(Habit.fromJson)
          .toList();
    } catch (e) {
      throw Exception('Unable to fetch habits: $e');
    }
  }
}
