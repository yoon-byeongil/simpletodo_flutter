import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // ... (기존 init 코드와 동일) ...
    tz.initializeTimeZones();

    try {
      tz.setLocalLocation(tz.getLocation('Asia/Tokyo'));
    } catch (e) {
      // 혹시나 실패하면 기본 UTC로 설정
      tz.setLocalLocation(tz.UTC);
    }

    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@drawable/launch_background');
    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(requestAlertPermission: true, requestBadgePermission: true, requestSoundPermission: true);
    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    final platform = flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (platform != null) {
      await platform.requestNotificationsPermission();
    }
  }

  Future<void> scheduleNotification({required int id, required String title, required DateTime scheduledTime}) async {
    debugPrint("🔍 [알림요청] ----------------------------------------");
    debugPrint("1. 예약할 시간(입력값): $scheduledTime");
    debugPrint("2. 현재 핸드폰 시간(시스템): ${DateTime.now()}");

    if (scheduledTime.isBefore(DateTime.now())) {
      debugPrint("❌ [실패] 과거 시간입니다. 알림을 예약하지 않습니다.");
      debugPrint("---------------------------------------------------");
      return;
    }

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        '할 일 알림',
        title,
        tz.TZDateTime.from(scheduledTime, tz.local),
        const NotificationDetails(
          iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
          android: AndroidNotificationDetails('todo_channel_id_v2', 'Todo Notifications V2', importance: Importance.max, priority: Priority.high),
        ),
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      // 이 줄이 콘솔에 떠야 성공입니다!
      debugPrint("✅ [성공] 알림 예약 완료! (잠시 후 알림이 울려야 정상)");
    } catch (e) {
      debugPrint("🔥 [에러] 알림 예약 실패: $e");
    }
    debugPrint("---------------------------------------------------");
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  // [추가된 기능] 모든 알림 일괄 취소
  Future<void> cancelAll() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
