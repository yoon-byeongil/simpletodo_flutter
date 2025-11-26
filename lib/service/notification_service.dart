import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // [최종 확정] 알림 채널 정보
  static const String channelId = 'simpletodo_channel';
  static const String channelName = 'Task Notifications';
  static const String channelDesc = 'Notifications for task deadlines';

  Future<void> init() async {
    // 1. 시간대 설정
    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Tokyo'));
    } catch (e) {
      tz.setLocalLocation(tz.UTC);
    }

    // 2. 초기화 설정
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(requestAlertPermission: true, requestBadgePermission: true, requestSoundPermission: true);

    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid, iOS: initializationSettingsIOS);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // 3. [핵심] 안드로이드 알림 채널 명시적 생성
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation = flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          channelId,
          channelName,
          description: channelDesc,
          importance: Importance.max, // 중요도는 여기서 설정
          playSound: true,
          // priority: Priority.high,  <-- [삭제됨] 이 줄이 오류의 원인이었습니다. 지웠습니다.
        ),
      );

      await androidImplementation.requestNotificationsPermission();
    }

    // 4. 권한 체크
    await _checkAndroidSchedulePermission();
  }

  Future<void> _checkAndroidSchedulePermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.scheduleExactAlarm.status;
      if (status.isDenied) {
        await Permission.scheduleExactAlarm.request();
      }
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
          iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription: channelDesc,
            importance: Importance.max,
            priority: Priority.high, // 개별 알림에는 priority가 있습니다 (정상)
          ),
        ),
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      debugPrint("✅ 알림 예약 성공: $scheduledTime - $title");
    } catch (e) {
      debugPrint("🔥 알림 예약 실패: $e");
    }
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> cancelAll() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
