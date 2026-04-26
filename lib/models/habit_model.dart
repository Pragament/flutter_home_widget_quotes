class Habit {
  final String title;
  final String description;
  final String category;
  final List<String> tags;
  final String? scheduleTime;

  const Habit({
    required this.title,
    required this.description,
    required this.category,
    required this.tags,
    this.scheduleTime,
  });

  factory Habit.fromJson(Map<String, dynamic> json) {
    final rawTime =
        json['scheduleTime'] ??
        json['schedule_time'] ??
        json['time'];
    return Habit(
      title: (json['title'] as String?)?.trim() ?? '',
      description: (json['description'] as String?)?.trim() ?? '',
      category: (json['category'] as String?)?.trim() ?? '',
      tags: (json['tags'] as List<dynamic>? ?? [])
          .map((tag) => tag.toString())
          .toList(),
      scheduleTime: rawTime?.toString(),
    );
  }
}
