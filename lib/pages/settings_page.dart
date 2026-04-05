import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/quote_model.dart';
import '../models/tag_settings_model.dart';
import '../models/todo_model.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late Box<TagSettingsModel> _tagSettingsBox;
  late List<String> _tags;

  @override
  void initState() {
    super.initState();
    _tagSettingsBox = Hive.box<TagSettingsModel>('tagSettingsBox');
    _tags = _loadUniqueTags();
    _ensureTagSettings();
  }

  List<String> _loadUniqueTags() {
    final quoteBox = Hive.box<QuoteModel>('quotesBox');
    final todoBox = Hive.box<Todo>('todos');

    final quoteTags = quoteBox.values
        .expand((quote) => quote.tags.map((tag) => tag.name))
        .where((tag) => tag.trim().isNotEmpty);
    final todoTags = todoBox.values
        .expand((todo) => todo.tags)
        .where((tag) => tag.trim().isNotEmpty);

    final uniqueTags = {...quoteTags, ...todoTags}.toList()..sort();
    return uniqueTags;
  }

  void _ensureTagSettings() {
    for (final tag in _tags) {
      if (!_tagSettingsBox.containsKey(tag)) {
        _tagSettingsBox.put(
          tag,
          TagSettingsModel(tagName: tag),
        );
      }
    }
  }

  Future<void> _pickTimeForTag(TagSettingsModel settings) async {
    final initialTime = _parseInitialTime(settings.scheduledTime);
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (selectedTime == null) {
      return;
    }

    settings.scheduledTime = _formatTime(selectedTime);
    await _tagSettingsBox.put(settings.tagName, settings);
  }

  TimeOfDay _parseInitialTime(String? value) {
    if (value == null || !value.contains(':')) {
      return TimeOfDay.now();
    }

    final parts = value.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? TimeOfDay.now().hour,
      minute: int.tryParse(parts[1]) ?? TimeOfDay.now().minute,
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ValueListenableBuilder(
        valueListenable: _tagSettingsBox.listenable(),
        builder: (context, Box<TagSettingsModel> box, _) {
          if (_tags.isEmpty) {
            return const Center(
              child: Text('No tags found.'),
            );
          }

          return ListView.builder(
            itemCount: _tags.length,
            itemBuilder: (context, index) {
              final tagName = _tags[index];
              final settings =
                  box.get(tagName) ?? TagSettingsModel(tagName: tagName);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tagName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Time: ${settings.scheduledTime ?? 'Not set'}',
                            ),
                          ),
                          TextButton(
                            onPressed: () => _pickTimeForTag(settings),
                            child: const Text('Set Time'),
                          ),
                        ],
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Notifications'),
                        value: settings.notificationEnabled,
                        onChanged: (value) async {
                          settings.notificationEnabled = value;
                          await box.put(tagName, settings);
                        },
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Wallpaper'),
                        value: settings.wallpaperEnabled,
                        onChanged: (value) async {
                          settings.wallpaperEnabled = value;
                          await box.put(tagName, settings);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
