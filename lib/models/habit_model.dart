class Habit {
  final String title;
  final String description;
  final String category;
  final List<String> tags;

  const Habit({
    required this.title,
    required this.description,
    required this.category,
    required this.tags,
  });

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      title: (json['title'] as String?)?.trim() ?? '',
      description: (json['description'] as String?)?.trim() ?? '',
      category: (json['category'] as String?)?.trim() ?? '',
      tags: (json['tags'] as List<dynamic>? ?? [])
          .map((tag) => tag.toString())
          .toList(),
    );
  }
}
