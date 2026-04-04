import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../helper/todo_box_helper.dart';
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
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final todo = box.getAt(index);
                  if (todo == null) {
                    return const SizedBox.shrink();
                  }

                  return CheckboxListTile(
                    value: todo.isCompleted,
                    onChanged: (value) async {
                      todo.isCompleted = value ?? false;
                      await box.putAt(index, todo);
                    },
                    title: Text(
                      todo.title.isEmpty ? 'Untitled Todo' : todo.title,
                    ),
                    subtitle: Text(
                      todo.category.isEmpty ? 'Uncategorized' : todo.category,
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
