import 'package:flutter/material.dart';

import '../models/habit_model.dart';
import '../services/habit_service.dart';

class HabitImportPage extends StatefulWidget {
  const HabitImportPage({super.key});

  @override
  State<HabitImportPage> createState() => _HabitImportPageState();
}

class _HabitImportPageState extends State<HabitImportPage> {
  late Future<List<Habit>> _habitsFuture;

  @override
  void initState() {
    super.initState();
    _habitsFuture = HabitService().fetchHabits();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Habits'),
      ),
      body: FutureBuilder<List<Habit>>(
        future: _habitsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  snapshot.error.toString(),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final habits = snapshot.data ?? [];
          if (habits.isEmpty) {
            return const Center(
              child: Text('No habits found.'),
            );
          }

          return ListView.separated(
            itemCount: habits.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final habit = habits[index];
              return ListTile(
                title: Text(habit.title.isEmpty ? 'Untitled Habit' : habit.title),
                subtitle: Text(
                  habit.category.isEmpty ? 'Uncategorized' : habit.category,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
