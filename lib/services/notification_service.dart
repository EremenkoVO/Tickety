import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/pass_record.dart';

const _channelId = 'events';
const _idPrefix = 'tickety-pass-';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.createNotificationChannel(AndroidNotificationChannel(
        _channelId,
        'Events',
        importance: Importance.defaultImportance,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 250, 250, 250]),
      ));
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted = await ios.requestPermissions(alert: true, sound: true);
      return granted ?? false;
    }
    return false;
  }

  DateTime? _parseEventDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      return DateTime.parse(raw.trim());
    } catch (_) {
      return null;
    }
  }

  String _notifTitle(PassRecord pass) =>
      pass.eventName?.trim().isNotEmpty == true
          ? pass.eventName!.trim()
          : pass.organizationName;

  int _hashId(String s) => s.hashCode.abs() % 100000;

  Future<void> schedulePassNotifications(
      PassRecord pass, Locale locale) async {
    final eventDate = _parseEventDate(pass.eventDate);
    if (eventDate == null || eventDate.isBefore(DateTime.now())) return;

    final name = _notifTitle(pass);
    final isRu = locale.languageCode == 'ru';
    final reminderTitle = isRu ? 'Напоминание: $name' : 'Reminder: $name';
    final now = DateTime.now();

    final threeDaysBefore = DateTime(
        eventDate.year, eventDate.month, eventDate.day - 3, 10, 0);
    if (threeDaysBefore.isAfter(now)) {
      await _schedule(
        id: _hashId('$_idPrefix${pass.id}-3days'),
        title: reminderTitle,
        body: isRu ? 'До мероприятия осталось 3 дня' : 'Event in 3 days',
        scheduledDate: threeDaysBefore,
      );
    }

    final dayOf =
        DateTime(eventDate.year, eventDate.month, eventDate.day, 9, 0);
    if (dayOf.isAfter(now)) {
      await _schedule(
        id: _hashId('$_idPrefix${pass.id}-day'),
        title: reminderTitle,
        body: isRu ? 'Мероприятие сегодня' : 'Event is today',
        scheduledDate: dayOf,
      );
    }

    final oneHourBefore = eventDate.subtract(const Duration(hours: 1));
    if (oneHourBefore.isAfter(now)) {
      await _schedule(
        id: _hashId('$_idPrefix${pass.id}-1h'),
        title: reminderTitle,
        body: isRu ? 'До начала остался 1 час' : 'Starting in 1 hour',
        scheduledDate: oneHourBefore,
      );
    }
  }

  Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Events',
          channelDescription: 'Event reminders',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelPassNotifications(String passId) async {
    final tag = '$_idPrefix$passId';
    await _plugin.cancel(_hashId('$tag-3days'));
    await _plugin.cancel(_hashId('$tag-day'));
    await _plugin.cancel(_hashId('$tag-1h'));
  }
}
