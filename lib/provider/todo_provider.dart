import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import '../models/todo_model.dart';

class TodoProvider with ChangeNotifier {
  static const String _boxName = 'todosBox';
  static const String _habitsApiUrl = 'https://staticapis.pragament.com/daily/habits.json';

  List<TodoModel> _todos = [];
  List<Map<String, dynamic>> _availableHabits = [];
  bool _isLoadingHabits = false;

  List<TodoModel> get todos => List.unmodifiable(_todos);
  List<Map<String, dynamic>> get availableHabits => List.unmodifiable(_availableHabits);
  bool get isLoadingHabits => _isLoadingHabits;

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

  Future<void> addTodo(String title, bool isRecurring, {String? description, String? category, List<String>? tags, List<String>? checklist, Map<String, dynamic>? schedule}) async {
    final newTodo = TodoModel(
      title: title.trim(),
      isRecurring: isRecurring,
      description: description,
      category: category,
      tags: tags,
      checklist: checklist,
      schedule: schedule,
    );
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

  Future<void> editTodo(String id, String newTitle, bool isRecurring, {String? description, String? category, List<String>? tags, List<String>? checklist, Map<String, dynamic>? schedule}) async {
    final index = _todos.indexWhere((element) => element.id == id);
    if (index == -1) return;

    _todos[index].title = newTitle.trim();
    _todos[index].isRecurring = isRecurring;
    _todos[index].description = description;
    _todos[index].category = category;
    _todos[index].tags = tags;
    _todos[index].checklist = checklist;
    _todos[index].schedule = schedule;
    final box = Hive.box(_boxName);
    await box.put(_todos[index].id, _todos[index].toMap());
    notifyListeners();
  }

  Future<void> fetchHabitsFromApi() async {
    _isLoadingHabits = true;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse(_habitsApiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final habits = data['habits'] as List<dynamic>;
        _availableHabits = habits.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        _availableHabits = [];
      }
    } catch (e) {
      _availableHabits = [];
    } finally {
      _isLoadingHabits = false;
      notifyListeners();
    }
  }

  Future<void> importHabits(List<Map<String, dynamic>> selectedHabits) async {
    for (final habit in selectedHabits) {
      await addTodo(
        habit['title'] as String,
        true, // All imported habits are recurring
        description: habit['description'] as String?,
        category: habit['category'] as String?,
        tags: habit['tags'] != null ? List<String>.from(habit['tags']) : null,
        checklist: habit['checklist'] != null ? List<String>.from(habit['checklist']) : null,
        schedule: habit['schedule'] != null ? Map<String, dynamic>.from(habit['schedule']) : null,
      );
    }
  }
}
