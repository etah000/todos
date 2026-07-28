// lib/core/notifications/notification_service.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Last notification payload the user tapped (warm tap) or which launched
  /// the app (cold start). Consumed once by [consumePendingTap].
  String? _pendingTap;

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          _pendingTap = payload;
        }
      },
    );

    // Seed from a cold-start launch (user tapped the notification to open the
    // app): the callback above only fires for warm taps, not the launch tap.
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch != null && launch.didNotificationLaunchApp) {
      final payload = launch.notificationResponse?.payload;
      if (payload != null && payload.isNotEmpty) {
        _pendingTap = payload;
      }
    }

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();
    _initialized = true;
  }

  /// Returns the payload of a notification tap that launched the app or
  /// occurred while it was in the background, and clears it. Returns null
  /// if there is no pending tap.
  String? consumePendingTap() {
    final p = _pendingTap;
    _pendingTap = null;
    return p;
  }

  /// Test-only helper to seed the pending-tap slot without booting the
  /// notification plugin. Production code uses the tap callback / launch
  /// details inside [init].
  @visibleForTesting
  void debugSetPendingTap(String? payload) {
    _pendingTap = payload;
  }

  /// Stable, positive 32-bit id derived from a key.
  /// Used so the same todo always reuses the same notification id
  /// (allowing cancel+reschedule to update the fire time).
  static int idForKey(String key) {
    var h = 0;
    for (final cu in key.codeUnits) {
      h = 0x1fffffff & (h + cu);
      h = 0x1fffffff & (h + ((0x0007ffff & h) << 10));
      h ^= h >> 6;
    }
    h = 0x1fffffff & (h + ((0x03ffffff & h) << 3));
    h ^= h >> 11;
    h = 0x1fffffff & (h + ((0x00003fff & h) << 15));
    final v = h ^ (h >> 16);
    return v & 0x7fffffff;
  }

  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime when,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    if (!_initialized) await init();
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final canExact =
        await androidImpl?.canScheduleExactNotifications() ?? false;
    await _scheduleWithMode(
      id: id,
      title: title,
      body: body,
      when: when,
      payload: payload,
      matchDateTimeComponents: matchDateTimeComponents,
      androidScheduleMode: canExact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> scheduleAlarm({
    required int id,
    required String title,
    required String body,
    required DateTime when,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    await _scheduleWithMode(
      id: id,
      title: title,
      body: body,
      when: when,
      payload: payload,
      matchDateTimeComponents: matchDateTimeComponents,
      androidScheduleMode: AndroidScheduleMode.alarmClock,
    );
  }

  Future<void> _scheduleWithMode({
    required int id,
    required String title,
    required String body,
    required DateTime when,
    required AndroidScheduleMode androidScheduleMode,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    if (!_initialized) await init();
    debugPrint(
      'NotificationService.schedule: id=$id title="$title" when=$when now=${DateTime.now()} match=$matchDateTimeComponents',
    );
    try {
      final scheduled = tz.TZDateTime.from(when, tz.local);
      debugPrint(
        'NotificationService.schedule: mode=$androidScheduleMode tzScheduled=$scheduled',
      );
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'todos_reminders',
            'Reminders',
            channelDescription: 'Todo reminders',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: androidScheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: matchDateTimeComponents,
        payload: payload,
      );
      debugPrint('NotificationService.schedule: zonedSchedule returned');
    } catch (err, st) {
      debugPrint('NotificationService.schedule failed: $err\n$st');
    }
  }

  Future<void> cancel(int id) async {
    if (!_initialized) await init();
    try {
      await _plugin.cancel(id);
    } catch (err) {
      debugPrint('NotificationService.cancel failed: $err');
    }
  }
}
