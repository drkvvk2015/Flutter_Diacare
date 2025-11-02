import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../telemedicine/appointment_model.dart';

class AppointmentNotifications {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );
    await _plugin.initialize(settings);
  }

  static Future<void> scheduleReminder(Appointment appt) async {
    final scheduledTime = tz.TZDateTime.from(
      appt.time.subtract(const Duration(minutes: 30)),
      tz.local,
    );
    await _plugin.zonedSchedule(
      appt.hashCode,
      'Appointment Reminder',
      'You have an appointment at ${appt.time.toString().substring(0, 16)}',
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'appt_channel',
          'Appointments',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
