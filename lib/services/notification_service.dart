import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();
  final _plugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(
        android: android, iOS: DarwinInitializationSettings());
    await _plugin.initialize(settings);
  }

  Future<void> showBudgetNotice(String title, String body) async {
    const details = NotificationDetails(
        android: AndroidNotificationDetails('budget_updates', 'Budget updates',
            channelDescription: 'Budget and transaction alerts',
            importance: Importance.defaultImportance),
        iOS: DarwinNotificationDetails());
    await _plugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000, title, body, details);
  }
}
