import 'package:flutter/material.dart';
import 'package:home_widget_counter/helper/settings_helper.dart';
import 'package:home_widget_counter/models/tag_model.dart';
import 'package:home_widget_counter/provider/tag_provider.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';

class BulkEditDialog extends StatefulWidget {
  final TimeOfDay? initialTime;
  final bool initialNotifications;
  final bool initialWallpaper;

  const BulkEditDialog({
    super.key,
    this.initialTime,
    this.initialNotifications = false,
    this.initialWallpaper = false,
  });

  @override
  State<BulkEditDialog> createState() => _BulkEditDialogState();
}

class _BulkEditDialogState extends State<BulkEditDialog> {
  TimeOfDay? selectedTime;
  bool enableNotifications = false;
  bool enableWallpaper = false;

  @override
  void initState() {
    super.initState();
    selectedTime = widget.initialTime;
    enableNotifications = widget.initialNotifications;
    enableWallpaper = widget.initialWallpaper;
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Bulk Edit Schedules'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text('Schedule Time: '),
                TextButton(
                  onPressed: () => _selectTime(context),
                  child: Text(selectedTime?.format(context) ?? 'Not set'),
                ),
              ],
            ),
            SwitchListTile(
              title: const Text('Enable Notifications'),
              value: enableNotifications,
              onChanged: (value) {
                setState(() {
                  enableNotifications = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Enable Wallpaper'),
              value: enableWallpaper,
              onChanged: (value) {
                setState(() {
                  enableWallpaper = value;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop({
            'time': selectedTime,
            'notifications': enableNotifications,
            'wallpaper': enableWallpaper,
          }),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  List<TagModel> tags = [];
  Set<String> selectedTags = {};
  bool isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  Future<void> _loadTags() async {
    final tagProvider = Provider.of<TagProvider>(context, listen: false);
    await tagProvider.loadTags();
    setState(() {
      tags = tagProvider.tags;
    });
  }

  Future<void> _saveSettings() async {
    final tagProvider = Provider.of<TagProvider>(context, listen: false);
    for (var tag in tags) {
      await tagProvider.updateTag(tag);
    }
    // Cancel all existing tasks and register new ones
    await Workmanager().cancelAll();
    for (var tag in tags) {
      if (tag.scheduleTime != null &&
          (tag.enableNotifications || tag.enableWallpaper)) {
        final timeParts = tag.scheduleTime!.split(':');
        final time = TimeOfDay(
            hour: int.parse(timeParts[0]), minute: int.parse(timeParts[1]));
        await Workmanager().registerPeriodicTask(
          'scheduleTask_${tag.id}',
          'scheduleTask',
          frequency: const Duration(hours: 24),
          initialDelay: _calculateInitialDelay(time),
          inputData: {'tagId': tag.id},
        );
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved')),
    );
  }

  Duration _calculateInitialDelay(TimeOfDay time) {
    final now = DateTime.now();
    final scheduledTime =
        DateTime(now.year, now.month, now.day, time.hour, time.minute);
    if (scheduledTime.isBefore(now)) {
      return scheduledTime.add(const Duration(days: 1)).difference(now);
    } else {
      return scheduledTime.difference(now);
    }
  }

  void _updateTag(TagModel updatedTag) {
    setState(() {
      final index = tags.indexWhere((tag) => tag.id == updatedTag.id);
      if (index != -1) {
        tags[index] = updatedTag;
      }
    });
  }

  void _toggleSelection(String tagId) {
    setState(() {
      if (selectedTags.contains(tagId)) {
        selectedTags.remove(tagId);
      } else {
        selectedTags.add(tagId);
      }
    });
  }

  void _selectAll() {
    setState(() {
      if (selectedTags.length == tags.length) {
        selectedTags.clear();
      } else {
        selectedTags = tags.map((tag) => tag.id).toSet();
      }
    });
  }

  Future<void> _bulkEdit() async {
    if (selectedTags.isEmpty) return;

    TimeOfDay? selectedTime;
    bool enableNotifications = false;
    bool enableWallpaper = false;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => BulkEditDialog(
        initialTime: selectedTime,
        initialNotifications: enableNotifications,
        initialWallpaper: enableWallpaper,
      ),
    );

    if (result != null) {
      selectedTime = result['time'];
      enableNotifications = result['notifications'];
      enableWallpaper = result['wallpaper'];

      for (var tagId in selectedTags) {
        final tag = tags.firstWhere((t) => t.id == tagId);
        final updatedTag = TagModel(
          id: tag.id,
          name: tag.name,
          scheduleTime: selectedTime != null
              ? '${selectedTime.hour}:${selectedTime.minute}'
              : null,
          enableNotifications: enableNotifications,
          enableWallpaper: enableWallpaper,
        );
        _updateTag(updatedTag);
      }
      setState(() {
        selectedTags.clear();
        isSelectionMode = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isSelectionMode
            ? 'Select Tags (${selectedTags.length})'
            : 'Tag Schedules'),
        actions: [
          if (isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: _selectAll,
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: selectedTags.isNotEmpty ? _bulkEdit : null,
            ),
            IconButton(
              icon: const Icon(Icons.cancel),
              onPressed: () {
                setState(() {
                  selectedTags.clear();
                  isSelectionMode = false;
                });
              },
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  isSelectionMode = true;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveSettings,
            ),
          ],
        ],
      ),
      body: ListView.builder(
        itemCount: tags.length,
        itemBuilder: (context, index) {
          final tag = tags[index];
          return TagScheduleTile(
            tag: tag,
            onUpdate: _updateTag,
            isSelectionMode: isSelectionMode,
            isSelected: selectedTags.contains(tag.id),
            onToggleSelection: () => _toggleSelection(tag.id),
          );
        },
      ),
    );
  }
}

class TagScheduleTile extends StatefulWidget {
  final TagModel tag;
  final Function(TagModel) onUpdate;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onToggleSelection;

  const TagScheduleTile({
    super.key,
    required this.tag,
    required this.onUpdate,
    this.isSelectionMode = false,
    this.isSelected = false,
    required this.onToggleSelection,
  });

  @override
  State<TagScheduleTile> createState() => _TagScheduleTileState();
}

class _TagScheduleTileState extends State<TagScheduleTile> {
  late TagModel tag;

  @override
  void initState() {
    super.initState();
    tag = widget.tag;
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: tag.scheduleTime != null
          ? TimeOfDay(
              hour: int.parse(tag.scheduleTime!.split(':')[0]),
              minute: int.parse(tag.scheduleTime!.split(':')[1]),
            )
          : TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        tag = TagModel(
          id: tag.id,
          name: tag.name,
          scheduleTime: '${picked.hour}:${picked.minute}',
          enableNotifications: tag.enableNotifications,
          enableWallpaper: tag.enableWallpaper,
        );
      });
      widget.onUpdate(tag);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      color: widget.isSelected ? Colors.blue.shade50 : null,
      child: InkWell(
        onTap: widget.isSelectionMode ? widget.onToggleSelection : null,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              if (widget.isSelectionMode)
                Checkbox(
                  value: widget.isSelected,
                  onChanged: (_) => widget.onToggleSelection(),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tag.name,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    if (!widget.isSelectionMode) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Text('Schedule Time: '),
                          TextButton(
                            onPressed: () => _selectTime(context),
                            child: Text(tag.scheduleTime ?? 'Not set'),
                          ),
                        ],
                      ),
                      SwitchListTile(
                        title: const Text('Enable Notifications'),
                        value: tag.enableNotifications,
                        onChanged: (value) {
                          setState(() {
                            tag = TagModel(
                              id: tag.id,
                              name: tag.name,
                              scheduleTime: tag.scheduleTime,
                              enableNotifications: value,
                              enableWallpaper: tag.enableWallpaper,
                            );
                          });
                          widget.onUpdate(tag);
                        },
                      ),
                      SwitchListTile(
                        title: const Text('Enable Wallpaper'),
                        value: tag.enableWallpaper,
                        onChanged: (value) {
                          setState(() {
                            tag = TagModel(
                              id: tag.id,
                              name: tag.name,
                              scheduleTime: tag.scheduleTime,
                              enableNotifications: tag.enableNotifications,
                              enableWallpaper: value,
                            );
                          });
                          widget.onUpdate(tag);
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
