import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationsHelper {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'habit_reminders',
    'Habit Reminders',
    description: 'Notifications for scheduled habit reminders',
    importance: Importance.high,
  );

  static Future<void> initialize({bool requestPermission = false}) async {
    if (_isInitialized) {
      if (requestPermission) {
        await _requestPermission();
      }
      return;
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings = InitializationSettings(
      android: androidSettings,
    );

    await _plugin.initialize(initializationSettings);

    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(_channel);
    _isInitialized = true;

    if (requestPermission) {
      await _requestPermission();
    }
  }

  static Future<void> _requestPermission() async {
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
  }

  static Future<void> showNotification({
    required int notificationId,
    required String title,
    required String body,
  }) async {
    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'habit_reminders',
        'Habit Reminders',
        channelDescription: 'Notifications for scheduled habit reminders',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );

    await _plugin.show(
      notificationId,
      title,
      body,
      notificationDetails,
    );
  }
}
