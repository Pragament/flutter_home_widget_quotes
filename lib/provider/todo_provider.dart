import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/todo_model.dart';

class TodoProvider with ChangeNotifier {
  static const String _boxName = 'todosBox';

  List<TodoModel> _todos = [];

  List<TodoModel> get todos => List.unmodifiable(_todos);

  List<TodoModel> get pendingTodos =>
      _todos.where((todo) => !todo.isDone || todo.isRecurring).toList();

  List<TodoModel> get completedTodos =>
      _todos.where((todo) => todo.isDone && !todo.isRecurring).toList();

  TodoProvider() {
    _loadTodos();
  }

  Future<void> _loadTodos() async {
    final box = await Hive.openBox(_boxName);
    _todos = box.values
        .map((e) => TodoModel.fromMap(Map<String, dynamic>.from(e)))
        .toList();
    notifyListeners();
  }

  Future<void> addTodo(String title, bool isRecurring) async {
    final newTodo = TodoModel(title: title.trim(), isRecurring: isRecurring);
    _todos.add(newTodo);
    final box = Hive.box(_boxName);
    await box.put(newTodo.id, newTodo.toMap());
    notifyListeners();
  }

  Future<void> deleteTodo(String id) async {
    _todos.removeWhere((todo) => todo.id == id);
    final box = Hive.box(_boxName);
    await box.delete(id);
    notifyListeners();
  }

  Future<void> toggleTodo(TodoModel todo) async {
    final index = _todos.indexWhere((element) => element.id == todo.id);
    if (index == -1) return;

    if (todo.isRecurring) {
      _todos[index].lastCompletedAt = DateTime.now();
      _todos[index].isDone = false;
    } else {
      _todos[index].isDone = !todo.isDone;
      _todos[index].completedAt = _todos[index].isDone ? DateTime.now() : null;
    }

    final box = Hive.box(_boxName);
    await box.put(_todos[index].id, _todos[index].toMap());
    notifyListeners();
  }

  Future<void> editTodo(String id, String newTitle, bool isRecurring) async {
    final index = _todos.indexWhere((element) => element.id == id);
    if (index == -1) return;

    _todos[index].title = newTitle.trim();
    _todos[index].isRecurring = isRecurring;
    final box = Hive.box(_boxName);
    await box.put(_todos[index].id, _todos[index].toMap());
    notifyListeners();
  }
}
