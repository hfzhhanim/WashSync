import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();
    
    // 1. Android Settings: Ensure you have an icon named 'app_icon' or use '@mipmap/ic_launcher'
    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // 2. iOS Settings
    const DarwinInitializationSettings iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );
    
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // You can add logic here to navigate to a specific page when the user taps the notification
      },
    );

    // 3. Request permissions for Android 13+
    await requestPermissions();
  }

  static Future<void> requestPermissions() async {
    // Request notification permission
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    // Request Exact Alarm permission for Android 13+ (Required for precise scheduling)
    final androidImplementation = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestExactAlarmsPermission();
    }
  }

  /// Use this for "Arrival Reminder", "5-min Warning", and "Finished" alerts
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    // Prevent scheduling if the time has already passed
    if (scheduledTime.isBefore(DateTime.now())) return;

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidInitializationSettings('@mipmap/ic_launcher') != null 
        ? AndroidNotificationDetails(
          'laundry_alerts', // Channel ID
          'Laundry Alerts', // Channel Name
          channelDescription: 'Notifications for machine status and bookings',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
        ) : null,
        iOS: DarwinNotificationDetails(),
      ),
      // exactAllowWhileIdle is crucial for the "5 minutes remaining" to be on time
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}