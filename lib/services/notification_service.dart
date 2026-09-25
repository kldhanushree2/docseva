import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

/// Schedules a real local (on-device) notification for each reminder, so
/// "how it will remind" has an actual answer: the OS pops a notification at
/// reminderDate. Previously reminders were saved to Firestore but nothing
/// ever scheduled a notification for them.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    // Falls back to UTC if the device's local timezone name can't be
    // determined; the notification will still fire, just against UTC
    // clock time instead of the device's local time in rare edge cases.
    try {
      tz.setLocalLocation(tz.getLocation(DateTime.now().timeZoneName));
    } catch (_) {
      // Leave default (UTC) — safer than crashing app startup over this.
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
    await _plugin.initialize(initSettings);

    // Android 13+ requires explicit runtime permission for notifications.
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();
    await androidImpl?.requestExactAlarmsPermission();

    final iosImpl = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await iosImpl?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;
  }

  /// Schedules a one-off notification for [reminderId] at [scheduledDate].
  /// If the date is already in the past, fires immediately instead of
  /// silently doing nothing, so the user still gets told.
  Future<void> scheduleReminder({
    required int reminderId,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    if (!_initialized) await init();

    const androidDetails = AndroidNotificationDetails(
      'docseva_reminders',
      'Document Reminders',
      channelDescription: 'Reminders for document expiry and renewals',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    final effectiveDate = scheduledDate.isAfter(DateTime.now())
        ? scheduledDate
        : DateTime.now().add(const Duration(seconds: 5));

    try {
      await _plugin.zonedSchedule(
        reminderId,
        title,
        body,
        tz.TZDateTime.from(effectiveDate, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      // Exact-alarm scheduling can be denied on some Android builds/OEMs
      // even after requesting the permission; fall back to inexact so the
      // reminder still fires (possibly a few minutes late) instead of never.
      debugPrint('NotificationService: exact schedule failed ($e), retrying inexact.');
      await _plugin.zonedSchedule(
        reminderId,
        title,
        body,
        tz.TZDateTime.from(effectiveDate, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  Future<void> cancelReminder(int reminderId) => _plugin.cancel(reminderId);
}
