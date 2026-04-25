import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../helper/todo_scheduler.dart';
import '../models/quote_model.dart';
import '../models/tag_settings_model.dart';
import '../models/todo_model.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class Changes {
  final TimeOfDay? time;
  final bool? notifications;
  final bool? wallpaper;

  const Changes({
    required this.time,
    required this.notifications,
    required this.wallpaper,
  });
}

class PendingChanges {
  TimeOfDay? time;
  bool? notifications;
  bool? wallpaper;

  PendingChanges({
    this.time,
    this.notifications,
    this.wallpaper,
  });
}

class _SettingsPageState extends State<SettingsPage> {
  late Box<TagSettingsModel> _tagSettingsBox;
  late List<String> _tags;
  bool isEditMode = false;
  bool _isApplyingBulkEdit = false;
  bool _isSavingPendingChanges = false;
  final Map<String, PendingChanges> pendingChanges = {};
  bool hasUnsavedChanges = false;
  final Set<String> selectedTagIds = {};

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
    await syncTagSchedules(onlyTagName: settings.tagName);
    await syncTodoSchedules();
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

  void _toggleTagSelection(String tagId) {
    setState(() {
      if (selectedTagIds.contains(tagId)) {
        selectedTagIds.remove(tagId);
      } else {
        selectedTagIds.add(tagId);
      }
    });
  }

  Future<Changes?> _showBulkEditDialog() async {
    TimeOfDay? selectedTime;
    bool? notificationEnabled;
    bool? wallpaperEnabled;

    return showDialog<Changes>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final localizations = MaterialLocalizations.of(context);
            final timeText = selectedTime == null
                ? 'Not set'
                : localizations.formatTimeOfDay(selectedTime!);

            return AlertDialog(
              title: const Text('Bulk Edit'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(child: Text('Time')),
                        TextButton(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: selectedTime ?? TimeOfDay.now(),
                            );
                            if (picked != null) {
                              setDialogState(() {
                                selectedTime = picked;
                              });
                            }
                          },
                          child: Text(timeText),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Notifications'),
                      subtitle: notificationEnabled == null
                          ? const Text('No change')
                          : null,
                      value: notificationEnabled ?? false,
                      onChanged: (value) {
                        setDialogState(() {
                          notificationEnabled = value;
                        });
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Wallpaper'),
                      subtitle: wallpaperEnabled == null
                          ? const Text('No change')
                          : null,
                      value: wallpaperEnabled ?? false,
                      onChanged: (value) {
                        setDialogState(() {
                          wallpaperEnabled = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(
                      Changes(
                        time: selectedTime,
                        notifications: notificationEnabled,
                        wallpaper: wallpaperEnabled,
                      ),
                    );
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void applyBulkEdit(Set<String> ids, Changes changes) {
    if (ids.isEmpty) {
      return;
    }

    for (final tagId in ids) {
      final existing = pendingChanges[tagId] ?? PendingChanges();
      if (changes.time != null) {
        existing.time = changes.time;
      }
      if (changes.notifications != null) {
        existing.notifications = changes.notifications;
      }
      if (changes.wallpaper != null) {
        existing.wallpaper = changes.wallpaper;
      }
      pendingChanges[tagId] = existing;
    }

    setState(() {
      hasUnsavedChanges = pendingChanges.isNotEmpty;
    });
  }

  Future<void> _savePendingChanges() async {
    if (!hasUnsavedChanges || _isSavingPendingChanges) {
      return;
    }

    setState(() {
      _isSavingPendingChanges = true;
    });

    try {
      for (final entry in pendingChanges.entries) {
        final tagId = entry.key;
        final staged = entry.value;
        final settings =
            _tagSettingsBox.get(tagId) ?? TagSettingsModel(tagName: tagId);

        if (staged.time != null) {
          settings.scheduledTime = _formatTime(staged.time!);
        }
        if (staged.notifications != null) {
          settings.notificationEnabled = staged.notifications!;
        }
        if (staged.wallpaper != null) {
          settings.wallpaperEnabled = staged.wallpaper!;
        }

        await _tagSettingsBox.put(tagId, settings);
        await syncTagSchedules(onlyTagName: tagId);
      }

      if (!mounted) {
        return;
      }

      setState(() {
        pendingChanges.clear();
        hasUnsavedChanges = false;
        isEditMode = false;
        selectedTagIds.clear();
      });
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(content: Text('Settings saved')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingPendingChanges = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final allSelected = _tags.isNotEmpty && selectedTagIds.length == _tags.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
            ),
            onPressed: hasUnsavedChanges && !_isSavingPendingChanges
                ? _savePendingChanges
                : null,
            child: const Text('Save'),
          ),
          if (isEditMode)
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  if (_tags.isEmpty || allSelected) {
                    selectedTagIds.clear();
                  } else {
                    selectedTagIds
                      ..clear()
                      ..addAll(_tags);
                  }
                });
              },
              child: Text(allSelected ? 'Deselect All' : 'Select All'),
            ),
          if (isEditMode)
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
              ),
              onPressed: selectedTagIds.isEmpty || _isApplyingBulkEdit
                  ? null
                  : () async {
                      final changes = await _showBulkEditDialog();
                      if (changes != null) {
                        if (_isApplyingBulkEdit) {
                          return;
                        }
                        setState(() {
                          _isApplyingBulkEdit = true;
                        });
                        try {
                          applyBulkEdit(selectedTagIds, changes);
                          if (!mounted) {
                            return;
                          }
                          setState(() {
                            isEditMode = false;
                            selectedTagIds.clear();
                          });
                        } finally {
                          if (mounted) {
                            setState(() {
                              _isApplyingBulkEdit = false;
                            });
                          }
                        }
                      }
                    },
              child: const Text('Edit'),
            ),
          IconButton(
            icon: Icon(isEditMode ? Icons.close : Icons.edit),
            onPressed: () {
              setState(() {
                isEditMode = !isEditMode;
                if (!isEditMode) {
                  selectedTagIds.clear();
                }
              });
            },
          ),
        ],
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
              final tagId = tagName;
              final isSelected = selectedTagIds.contains(tagId);
              final settings =
                  box.get(tagName) ?? TagSettingsModel(tagName: tagName);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                color: isSelected ? Colors.blue.shade50 : null,
                child: InkWell(
                  onTap: isEditMode ? () => _toggleTagSelection(tagId) : null,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (isEditMode)
                              Checkbox(
                                value: isSelected,
                                onChanged: (_) => _toggleTagSelection(tagId),
                              ),
                            Expanded(
                              child: Text(
                                tagName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        IgnorePointer(
                          ignoring: isEditMode,
                          child: Column(
                            children: [
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
                                  await syncTagSchedules(onlyTagName: tagName);
                                  await syncTodoSchedules();
                                },
                              ),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('Wallpaper'),
                                value: settings.wallpaperEnabled,
                                onChanged: (value) async {
                                  settings.wallpaperEnabled = value;
                                  await box.put(tagName, settings);
                                  await syncTagSchedules(onlyTagName: tagName);
                                  await syncTodoSchedules();
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
