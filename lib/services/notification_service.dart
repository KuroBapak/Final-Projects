import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as fln;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

class NotificationService {
  final fln.FlutterLocalNotificationsPlugin _notificationsPlugin = fln.FlutterLocalNotificationsPlugin();

  Future<void> get ready => _initCompleter.future;
  final Completer<void> _initCompleter = Completer<void>();

  NotificationService() {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      tz.initializeTimeZones();

      const fln.AndroidInitializationSettings initializationSettingsAndroid =
          fln.AndroidInitializationSettings('@mipmap/ic_launcher');

      const fln.DarwinInitializationSettings initializationSettingsIOS = fln.DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const fln.InitializationSettings initializationSettings = fln.InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _notificationsPlugin.initialize(initializationSettings);
      _initCompleter.complete();
    } catch (e) {
      debugPrint('Notification initialization failed: $e');
      _initCompleter.completeError(e);
    }
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    try {
      await ready; // Wait for initialization
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        const fln.NotificationDetails(
          android: fln.AndroidNotificationDetails(
            'expiry_channel',
            'Expiry Reminders',
            channelDescription: 'Notifications for item expirations',
            importance: fln.Importance.max,
            priority: fln.Priority.high,
          ),
          iOS: fln.DarwinNotificationDetails(),
        ),
        androidScheduleMode: fln.AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }
}
