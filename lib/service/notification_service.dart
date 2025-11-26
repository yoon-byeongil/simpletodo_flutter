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

  // [중요] 채널 ID를 변수로 관리해서 실수를 방지합니다.
  static const String channelId = 'todo_channel_final_v1';
  static const String channelName = 'Todo Notifications';

  Future<void> init() async {
    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Tokyo'));
    } catch (e) {
      tz.setLocalLocation(tz.UTC);
    }

    // 1. 초기화 설정
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher'); // 기본 아이콘 사용

    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(requestAlertPermission: true, requestBadgePermission: true, requestSoundPermission: true);

    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid, iOS: initializationSettingsIOS);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // 2. 안드로이드 플랫폼 구현체 가져오기
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation = flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    // ▼▼▼ [작성자님 제안] 채널 명시적 생성 코드 추가 ▼▼▼
    if (androidImplementation != null) {
      // 채널 생성 (여기서 중요도와 소리 설정을 확정짓습니다)
      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          channelId, // 위에서 정의한 ID
          channelName, // 위에서 정의한 이름
          importance: Importance.max, // 중요도 최상 (헤드업 알림 표시)
          playSound: true,
        ),
      );

      // 권한 요청도 여기서
      await androidImplementation.requestNotificationsPermission();
      // ▼▼▼ [추가] 정확한 알람(Exact Alarm) 권한 체크 및 요청 로직 ▼▼▼
      await _checkAndroidSchedulePermission();
    }
    // ▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲
  }

  Future<void> _checkAndroidSchedulePermission() async {
    // 안드로이드 12 (API 31) 이상에서만 필요한 권한입니다.
    if (defaultTargetPlatform == TargetPlatform.android) {
      // 현재 권한 상태 확인
      final status = await Permission.scheduleExactAlarm.status;

      if (status.isDenied) {
        debugPrint("⚠️ '정확한 알람' 권한이 없습니다. 설정 화면으로 이동합니다.");
        // 여기서는 심플하게 바로 권한 요청(설정창 이동)을 실행합니다.
        await Permission.scheduleExactAlarm.request();
      }
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
          // ▼▼▼ [중요] 위에서 만든 것과 똑같은 채널 ID 사용 ▼▼▼
          android: AndroidNotificationDetails(
            channelId, // 'todo_channel_final_v1'
            channelName, // 'Todo Notifications'
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      debugPrint("✅ [성공] 알림 예약 완료!");
    } catch (e) {
      debugPrint("🔥 [에러] 알림 예약 실패: $e");
    }
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  // [추가된 기능] 모든 알림 일괄 취소
  Future<void> cancelAll() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
