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
  final TextEditingController _searchController = TextEditingController();
  final Set<int> selectedIndexes = <int>{};
  List<Habit> allHabits = [];
  List<Habit> filteredHabits = [];
  List<String> categories = [];
  List<String> tags = [];
  String? selectedCategory;
  String? selectedTag;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applyFilters);
    _loadHabits();
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilters);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHabits() async {
    try {
      final habits = await HabitService().fetchHabits();
      final categorySet = habits
          .map((habit) => habit.category)
          .where((category) => category.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
      final tagSet = habits
          .expand((habit) => habit.tags)
          .where((tag) => tag.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

      setState(() {
        allHabits = habits;
        filteredHabits = List<Habit>.from(habits);
        categories = categorySet;
        tags = tagSet;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();

    setState(() {
      filteredHabits = allHabits.where((habit) {
        final matchesSearch =
            query.isEmpty ||
            habit.title.toLowerCase().contains(query) ||
            habit.description.toLowerCase().contains(query);
        final matchesCategory =
            selectedCategory == null || habit.category == selectedCategory;
        final matchesTag =
            selectedTag == null || habit.tags.contains(selectedTag);

        return matchesSearch && matchesCategory && matchesTag;
      }).toList();
    });
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
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : allHabits.isEmpty
                  ? const Center(
                      child: Text('No habits found.'),
                    )
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              hintText: 'Search by title or description',
                              prefixIcon: Icon(Icons.search),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: selectedCategory,
                                  decoration: const InputDecoration(
                                    labelText: 'Category',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: [
                                    const DropdownMenuItem<String>(
                                      value: null,
                                      child: Text('All Categories'),
                                    ),
                                    ...categories.map(
                                      (category) => DropdownMenuItem<String>(
                                        value: category,
                                        child: Text(category),
                                      ),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    selectedCategory = value;
                                    _applyFilters();
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: selectedTag,
                                  decoration: const InputDecoration(
                                    labelText: 'Tag',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: [
                                    const DropdownMenuItem<String>(
                                      value: null,
                                      child: Text('All Tags'),
                                    ),
                                    ...tags.map(
                                      (tag) => DropdownMenuItem<String>(
                                        value: tag,
                                        child: Text(tag),
                                      ),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    selectedTag = value;
                                    _applyFilters();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: selectedIndexes.isEmpty
                                  ? null
                                  : () async => _importSelected(allHabits),
                              child: Text(
                                'Import Selected (${selectedIndexes.length})',
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: filteredHabits.isEmpty
                              ? const Center(
                                  child: Text('No habits match the filters.'),
                                )
                              : ListView.separated(
                                  itemCount: filteredHabits.length,
                                  separatorBuilder: (_, __) =>
                                      const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final habit = filteredHabits[index];
                                    final originalIndex = allHabits.indexOf(habit);
                                    final isSelected =
                                        selectedIndexes.contains(originalIndex);

                                    return Container(
                                      color: isSelected
                                          ? Colors.blue.withOpacity(0.12)
                                          : null,
                                      child: CheckboxListTile(
                                        value: isSelected,
                                        onChanged: (_) =>
                                            _toggleSelection(originalIndex),
                                        title: Text(
                                          habit.title.isEmpty
                                              ? 'Untitled Habit'
                                              : habit.title,
                                        ),
                                        subtitle: Text(
                                          habit.category.isEmpty
                                              ? 'Uncategorized'
                                              : habit.category,
                                        ),
                                        controlAffinity:
                                            ListTileControlAffinity.leading,
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
    );
  }
}
