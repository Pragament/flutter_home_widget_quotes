import 'package:flutter/material.dart';

import '../helper/todo_box_helper.dart';
import '../models/habit_model.dart';
import '../models/todo_model.dart';
import '../services/habit_service.dart';
import 'todo_home_page.dart';

class HabitImportPage extends StatefulWidget {
  const HabitImportPage({super.key});

  @override
  State<HabitImportPage> createState() => _HabitImportPageState();
}

class _HabitImportPageState extends State<HabitImportPage> {
  late Future<List<Habit>> _habitsFuture;
  final Set<int> selectedIndexes = <int>{};

  @override
  void initState() {
    super.initState();
    _habitsFuture = HabitService().fetchHabits();
  }

  void _toggleSelection(int index) {
    setState(() {
      if (selectedIndexes.contains(index)) {
        selectedIndexes.remove(index);
      } else {
        selectedIndexes.add(index);
      }
    });
  }

  Future<void> _importSelected(List<Habit> habits) async {
    final todoBox = await TodoBoxHelper.getTodoBox();
    final selectedHabits = selectedIndexes.map((index) => habits[index]).toList();
    final newTodos = selectedHabits
        .map(
          (habit) => Todo(
            title: habit.title,
            description: habit.description,
            category: habit.category,
            tags: habit.tags,
          ),
        )
        .toList();

    final existingTitles = todoBox.values.map((todo) => todo.title).toSet();
    final seenTitles = <String>{...existingTitles};
    final todosToAdd = newTodos.where((todo) {
      if (seenTitles.contains(todo.title)) {
        return false;
      }
      seenTitles.add(todo.title);
      return true;
    }).toList();
    final duplicateCount = newTodos.length - todosToAdd.length;

    await todoBox.addAll(todosToAdd);

    setState(() {
      selectedIndexes.clear();
    });

    final importedCount = todosToAdd.length;
    final message = importedCount == 0
        ? 'No new habits imported. Selected habits already exist as todos.'
        : duplicateCount == 0
            ? '$importedCount habits imported successfully.'
            : '$importedCount habits imported. $duplicateCount duplicates skipped.';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TodoHomePage(),
      ),
    );
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

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: selectedIndexes.isEmpty
                        ? null
                        : () async => _importSelected(habits),
                    child: Text(
                      'Import Selected (${selectedIndexes.length})',
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: habits.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final habit = habits[index];
                    final isSelected = selectedIndexes.contains(index);

                    return Container(
                      color: isSelected ? Colors.blue.withOpacity(0.12) : null,
                      child: CheckboxListTile(
                        value: isSelected,
                        onChanged: (_) => _toggleSelection(index),
                        title: Text(
                          habit.title.isEmpty ? 'Untitled Habit' : habit.title,
                        ),
                        subtitle: Text(
                          habit.category.isEmpty
                              ? 'Uncategorized'
                              : habit.category,
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
