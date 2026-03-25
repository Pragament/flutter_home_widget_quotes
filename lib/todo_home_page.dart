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
  String? _description;
  String? _category;
  List<String> _tags = [];
  List<String> _checklist = [];
  Map<String, dynamic>? _schedule;

  Set<String> _selectedTodos = {};

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _showTodoDialog({TodoModel? existing}) async {
    if (existing != null) {
      _titleController.text = existing.title;
      _isRecurring = existing.isRecurring;
      _description = existing.description;
      _category = existing.category;
      _tags = existing.tags ?? [];
      _checklist = existing.checklist ?? [];
      _schedule = existing.schedule;
    } else {
      _titleController.clear();
      _isRecurring = false;
      _description = null;
      _category = null;
      _tags = [];
      _checklist = [];
      _schedule = null;
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(existing == null ? 'Add Todo' : 'Edit Todo'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
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
                  TextFormField(
                    initialValue: _description,
                    decoration: const InputDecoration(labelText: 'Description'),
                    onChanged: (value) => _description = value,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: _category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    onChanged: (value) => _category = value,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: _tags.join(', '),
                    decoration: const InputDecoration(labelText: 'Tags (comma separated)'),
                    onChanged: (value) => _tags = value.split(',').map((e) => e.trim()).toList(),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Recurring task'),
                    value: _isRecurring,
                    onChanged: (value) => setState(() => _isRecurring = value),
                  ),
                  if (_isRecurring) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: _schedule?['type'] ?? 'daily',
                      decoration: const InputDecoration(labelText: 'Schedule Type'),
                      onChanged: (value) => _schedule = {...?_schedule, 'type': value},
                    ),
                    // Add more schedule fields as needed
                  ],
                ],
              ),
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
                  await provider.addTodo(
                    _titleController.text,
                    _isRecurring,
                    description: _description,
                    category: _category,
                    tags: _tags,
                    checklist: _checklist,
                    schedule: _schedule,
                  );
                } else {
                  await provider.editTodo(
                    existing.id,
                    _titleController.text,
                    _isRecurring,
                    description: _description,
                    category: _category,
                    tags: _tags,
                    checklist: _checklist,
                    schedule: _schedule,
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
        actions: [
          if (_selectedTodos.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                // Bulk edit logic here
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bulk edit not implemented yet')),
                );
              },
            ),
        ],
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
                            return CheckboxListTile(
                              title: Text(
                                todo.title,
                                style: TextStyle(
                                  decoration: todo.isDone
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (todo.description != null) Text(todo.description!),
                                  if (todo.category != null) Text('Category: ${todo.category}'),
                                  if (todo.tags != null && todo.tags!.isNotEmpty) Text('Tags: ${todo.tags!.join(', ')}'),
                                  if (todo.isRecurring)
                                    Text(
                                      'Recurring · last: ${todo.lastCompletedAt != null ? todo.lastCompletedAt!.toLocal().toString().split('.').first : 'never'}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                ],
                              ),
                              value: _selectedTodos.contains(todo.id),
                              onChanged: (selected) {
                                setState(() {
                                  if (selected ?? false) {
                                    _selectedTodos.add(todo.id);
                                  } else {
                                    _selectedTodos.remove(todo.id);
                                  }
                                });
                              },
                              secondary: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
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
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (todo.description != null) Text(todo.description!),
                                  if (todo.category != null) Text('Category: ${todo.category}'),
                                  if (todo.tags != null && todo.tags!.isNotEmpty) Text('Tags: ${todo.tags!.join(', ')}'),
                                  if (todo.completedAt != null)
                                    Text('Done at: ${todo.completedAt!.toLocal().toString().split('.').first}'),
                                ],
                              ),
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
