import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_10y.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// ローカルプッシュ通知管理サービス
class NotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();

  /// 初期化処理
  static Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    tz.initializeTimeZones();

    await _notifications.initialize(initSettings);
  }

  /// 即時テスト通知をトリガー
  static Future<void> showInstantNotification({
    required String title,
    required String body,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'freshbox_channel',
        'FreshBox アラート',
        channelDescription: '食材の消費期限アラート',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _notifications.show(
      DateTime.now().millisecond,
      title,
      body,
      details,
    );
  }

  /// 特定の食材の賞味期限アラートを設定（賞味期限の2日前の朝8:30に通知）
  static Future<void> scheduleExpiryNotification({
    required String id,
    required String name,
    required DateTime expiryDate,
  }) async {
    // すでに設定されている同IDの通知をいったんキャンセル
    await cancelNotification(id);

    // 2日前の朝8時30分
    final notifyDate = expiryDate.subtract(const Duration(days: 2));
    final scheduledTime = DateTime(
      notifyDate.year,
      notifyDate.month,
      notifyDate.day,
      8,
      30,
    );

    // 予定時刻がすでに過去の場合はセットしない
    if (scheduledTime.isBefore(DateTime.now())) {
      return;
    }

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'freshbox_expiry_channel',
        '賞味期限のお知らせ',
        channelDescription: '賞味期限間近の食材をお知らせします',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _notifications.zonedSchedule(
      id.hashCode,
      '食材の期限が迫っています！',
      '「$name」の期限が2日後に迫っています。今日のレシピをチェックして無駄なく使い切りましょう。',
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// アラート通知をキャンセル
  static Future<void> cancelNotification(String id) async {
    await _notifications.cancel(id.hashCode);
  }
}
