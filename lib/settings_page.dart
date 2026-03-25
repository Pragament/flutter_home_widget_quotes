import 'package:flutter/material.dart';
import 'package:home_widget_counter/helper/settings_helper.dart';
import 'package:workmanager/workmanager.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _scheduleEnabled = false;
  TimeOfDay? _scheduleTime;
  bool _notificationsEnabled = false;
  bool _wallpaperEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _scheduleEnabled = await SettingsHelper.isScheduleEnabled();
    _scheduleTime = await SettingsHelper.getScheduleTime();
    _notificationsEnabled = await SettingsHelper.isNotificationsEnabled();
    _wallpaperEnabled = await SettingsHelper.isWallpaperEnabled();
    setState(() {});
  }

  Future<void> _saveSettings() async {
    await SettingsHelper.setScheduleEnabled(_scheduleEnabled);
    if (_scheduleTime != null) {
      await SettingsHelper.setScheduleTime(_scheduleTime!);
    }
    await SettingsHelper.setNotificationsEnabled(_notificationsEnabled);
    await SettingsHelper.setWallpaperEnabled(_wallpaperEnabled);

    // Schedule the workmanager task
    if (_scheduleEnabled && _scheduleTime != null) {
      await Workmanager().registerPeriodicTask(
        'scheduleTask',
        'scheduleTask',
        frequency: const Duration(hours: 24), // Daily
        initialDelay: _calculateInitialDelay(_scheduleTime!),
      );
    } else {
      await Workmanager().cancelByUniqueName('scheduleTask');
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
      // If the time has passed today, schedule for tomorrow
      return scheduledTime.add(const Duration(days: 1)).difference(now);
    } else {
      return scheduledTime.difference(now);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _scheduleTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _scheduleTime) {
      setState(() {
        _scheduleTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Enable Scheduled Updates'),
            value: _scheduleEnabled,
            onChanged: (value) {
              setState(() {
                _scheduleEnabled = value;
              });
            },
          ),
          if (_scheduleEnabled)
            ListTile(
              title: const Text('Schedule Time'),
              subtitle: Text(_scheduleTime?.format(context) ?? 'Not set'),
              onTap: () => _selectTime(context),
            ),
          SwitchListTile(
            title: const Text('Enable Notifications'),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text('Enable Wallpaper Change'),
            value: _wallpaperEnabled,
            onChanged: (value) {
              setState(() {
                _wallpaperEnabled = value;
              });
            },
          ),
          ElevatedButton(
            onPressed: _saveSettings,
            child: const Text('Save Settings'),
          ),
        ],
      ),
    );
  }
}
