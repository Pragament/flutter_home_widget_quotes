import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/todo_provider.dart';

class HabitImportPage extends StatefulWidget {
  const HabitImportPage({super.key});

  @override
  State<HabitImportPage> createState() => _HabitImportPageState();
}

class _HabitImportPageState extends State<HabitImportPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;
  List<String> _selectedTags = [];
  Set<String> _selectedHabits = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TodoProvider>(context, listen: false).fetchHabitsFromApi();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getFilteredHabits(TodoProvider provider) {
    return provider.availableHabits.where((habit) {
      final title = habit['title'] as String? ?? '';
      final description = habit['description'] as String? ?? '';
      final category = habit['category'] as String? ?? '';
      final tags = habit['tags'] as List<dynamic>? ?? [];

      final matchesSearch = title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          description.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == null || category == _selectedCategory;
      final matchesTags = _selectedTags.isEmpty || _selectedTags.every((tag) => tags.contains(tag));

      return matchesSearch && matchesCategory && matchesTags;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Habits'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _selectedHabits.isEmpty
                ? null
                : () async {
                    final provider = Provider.of<TodoProvider>(context, listen: false);
                    final selectedHabits = provider.availableHabits
                        .where((habit) => _selectedHabits.contains(habit['title']))
                        .toList();
                    await provider.importHabits(selectedHabits);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Imported ${selectedHabits.length} habits')),
                    );
                    Navigator.of(context).pop();
                  },
          ),
        ],
      ),
      body: Consumer<TodoProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingHabits) {
            return const Center(child: CircularProgressIndicator());
          }

          final filteredHabits = _getFilteredHabits(provider);
          final categories = provider.availableHabits
              .map((h) => h['category'] as String?)
              .where((c) => c != null)
              .toSet()
              .toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Search habits',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('All Categories'),
                      selected: _selectedCategory == null,
                      onSelected: (selected) => setState(() => _selectedCategory = null),
                    ),
                    ...categories.map((category) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FilterChip(
                        label: Text(category!),
                        selected: _selectedCategory == category,
                        onSelected: (selected) => setState(() => _selectedCategory = selected ? category : null),
                      ),
                    )),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: filteredHabits.length,
                  itemBuilder: (context, index) {
                    final habit = filteredHabits[index];
                    final title = habit['title'] as String? ?? '';
                    final description = habit['description'] as String? ?? '';
                    final category = habit['category'] as String? ?? '';
                    final tags = habit['tags'] as List<dynamic>? ?? [];

                    return CheckboxListTile(
                      title: Text(title),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (description.isNotEmpty) Text(description),
                          Text('Category: $category'),
                          if (tags.isNotEmpty) Text('Tags: ${tags.join(', ')}'),
                        ],
                      ),
                      value: _selectedHabits.contains(title),
                      onChanged: (selected) {
                        setState(() {
                          if (selected ?? false) {
                            _selectedHabits.add(title);
                          } else {
                            _selectedHabits.remove(title);
                          }
                        });
                      },
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