import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'provider/todo_provider.dart';
import 'models/todo_model.dart';

class TodoHomePage extends StatefulWidget {
  const TodoHomePage({super.key});

  @override
  State<TodoHomePage> createState() => _TodoHomePageState();
}

class _TodoHomePageState extends State<TodoHomePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  bool _isRecurring = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _showTodoDialog({TodoModel? existing}) async {
    if (existing != null) {
      _titleController.text = existing.title;
      _isRecurring = existing.isRecurring;
    } else {
      _titleController.clear();
      _isRecurring = false;
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(existing == null ? 'Add Todo' : 'Edit Todo'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Task title'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Recurring task'),
                  value: _isRecurring,
                  onChanged: (value) => setState(() => _isRecurring = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Save'),
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;

                final provider =
                    Provider.of<TodoProvider>(context, listen: false);

                if (existing == null) {
                  await provider.addTodo(_titleController.text, _isRecurring);
                } else {
                  await provider.editTodo(
                    existing.id,
                    _titleController.text,
                    _isRecurring,
                  );
                }

                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todo List'),
      ),
      body: Consumer<TodoProvider>(
        builder: (context, provider, child) {
          final pending = provider.pendingTodos;
          final completed = provider.completedTodos;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Active tasks',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Expanded(
                  flex: 2,
                  child: pending.isEmpty
                      ? const Center(child: Text('No active tasks yet.'))
                      : ListView.separated(
                          itemCount: pending.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, index) {
                            final todo = pending[index];
                            return ListTile(
                              leading: Checkbox(
                                value: todo.isDone,
                                onChanged: (_) => provider.toggleTodo(todo),
                              ),
                              title: Text(
                                todo.title,
                                style: TextStyle(
                                  decoration: todo.isDone
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                ),
                              ),
                              subtitle: todo.isRecurring
                                  ? Text(
                                      'Recurring · last: ${todo.lastCompletedAt != null ? todo.lastCompletedAt!.toLocal().toString().split('.').first : 'never'}',
                                      style: const TextStyle(fontSize: 12),
                                    )
                                  : null,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (!todo.isRecurring && todo.completedAt != null)
                                    const Icon(Icons.check, color: Colors.green),
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _showTodoDialog(existing: todo),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () => provider.deleteTodo(todo.id),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),

                const SizedBox(height: 12),
                const Text(
                  'Completed tasks',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Expanded(
                  flex: 1,
                  child: completed.isEmpty
                      ? const Center(child: Text('No completed one-time tasks.'))
                      : ListView.separated(
                          itemCount: completed.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, index) {
                            final todo = completed[index];
                            return ListTile(
                              title: Text(todo.title),
                              subtitle: todo.completedAt != null
                                  ? Text('Done at: ${todo.completedAt!.toLocal().toString().split('.').first}')
                                  : null,
                              trailing: IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => provider.deleteTodo(todo.id),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTodoDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
