import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static const String channelId = 'simpletodo_channel';
  static const String channelName = 'Task Notifications';
  static const String channelDesc = 'Notifications for task deadlines';

  Future<void> init() async {
    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Tokyo'));
    } catch (e) {
      tz.setLocalLocation(tz.UTC);
    }

    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
      defaultPresentBanner: true,
      defaultPresentList: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid, iOS: initializationSettingsIOS);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    final AndroidFlutterLocalNotificationsPlugin? androidImplementation = flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(const AndroidNotificationChannel(channelId, channelName, description: channelDesc, importance: Importance.max, playSound: true));
      await androidImplementation.requestNotificationsPermission();
    }
  }

  Future<void> scheduleNotification({required int id, required String title, required DateTime scheduledTime}) async {
    if (scheduledTime.isBefore(DateTime.now())) return;

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        'リマインダー',
        title,
        tz.TZDateTime.from(scheduledTime, tz.local),
        const NotificationDetails(
          iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true, presentBanner: true, presentList: true),
          android: AndroidNotificationDetails(channelId, channelName, channelDescription: channelDesc, importance: Importance.max, priority: Priority.high),
        ),
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      debugPrint("✅ 알림 예약 성공: $scheduledTime");
    } catch (e) {
      debugPrint("🔥 알림 예약 실패: $e");
    }
  }

  Future<void> showImmediateNotification({required int id, required String title}) async {
    try {
      await flutterLocalNotificationsPlugin.show(
        id,
        'リマインダー',
        title,
        const NotificationDetails(
          iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
          android: AndroidNotificationDetails(channelId, channelName, channelDescription: channelDesc, importance: Importance.max, priority: Priority.high),
        ),
      );
      debugPrint("✅ 즉시 알림 발송 성공");
    } catch (e) {
      debugPrint("🔥 즉시 알림 실패: $e");
    }
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> cancelAll() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
