import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../helper/todo_box_helper.dart';
import '../helper/todo_scheduler.dart';
import '../models/todo_model.dart';

class TodoHomePage extends StatefulWidget {
  const TodoHomePage({super.key});

  @override
  State<TodoHomePage> createState() => _TodoHomePageState();
}

class _TodoHomePageState extends State<TodoHomePage> {
  late Future<Box<Todo>> _todoBoxFuture;

  @override
  void initState() {
    super.initState();
    _todoBoxFuture = TodoBoxHelper.getTodoBox();
  }

  TimeOfDay _parseInitialTime(String? time) {
    if (time == null || !time.contains(':')) {
      return TimeOfDay.now();
    }

    final parts = time.split(':');
    final hour = int.tryParse(parts[0]) ?? TimeOfDay.now().hour;
    final minute = int.tryParse(parts[1]) ?? TimeOfDay.now().minute;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _pickScheduleTime(Box<Todo> box, int index, Todo todo) async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: _parseInitialTime(todo.scheduledTime),
    );

    if (selectedTime == null) {
      return;
    }

    todo.scheduledTime = _formatTime(selectedTime);
    await box.putAt(index, todo);
    await syncTodoSchedules();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Scheduled ${todo.title} at ${todo.scheduledTime}'),
      ),
    );
  }

  Future<void> _deleteTodo(Box<Todo> box, int index, Todo todo) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Todo'),
          content: Text('Delete "${todo.title}" from your todo list?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    await box.deleteAt(index);
    await syncTodoSchedules();
  }

  Widget _buildTodoDetails(Box<Todo> box, int index, Todo todo) {
    final tagsText = todo.tags.isEmpty ? 'No tags' : todo.tags.join(', ');
    final scheduleText = todo.scheduledTime == null || todo.scheduledTime!.isEmpty
        ? 'Not set'
        : todo.scheduledTime!;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: todo.isCompleted,
                  onChanged: (value) async {
                    todo.isCompleted = value ?? false;
                    await box.putAt(index, todo);
                  },
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        todo.title.isEmpty ? 'Untitled Todo' : todo.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        todo.description.isEmpty
                            ? 'No description'
                            : todo.description,
                      ),
                      const SizedBox(height: 8),
                      Text('Category: ${todo.category.isEmpty ? 'Uncategorized' : todo.category}'),
                      const SizedBox(height: 4),
                      Text('Tags: $tagsText'),
                      const SizedBox(height: 4),
                      Text('Time: $scheduleText'),
                    ],
                  ),
                ),
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.access_time),
                      onPressed: () => _pickScheduleTime(box, index, todo),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteTodo(box, index, todo),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todos'),
      ),
      body: FutureBuilder<Box<Todo>>(
        future: _todoBoxFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  snapshot.error?.toString() ?? 'Failed to open todos box.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final todoBox = snapshot.data!;
          return ValueListenableBuilder(
            valueListenable: todoBox.listenable(),
            builder: (context, Box<Todo> box, _) {
              if (box.isEmpty) {
                return const Center(
                  child: Text('No todos imported yet.'),
                );
              }

              return ListView.separated(
                itemCount: box.length,
                separatorBuilder: (_, __) => const SizedBox.shrink(),
                itemBuilder: (context, index) {
                  final todo = box.getAt(index);
                  if (todo == null) {
                    return const SizedBox.shrink();
                  }

                  return _buildTodoDetails(box, index, todo);
                },
              );
            },
          );
        },
      ),
    );
  }
}
