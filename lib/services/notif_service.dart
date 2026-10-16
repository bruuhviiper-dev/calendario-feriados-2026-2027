import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

import '../data/calendar_event.dart';
import '../data/holidays.dart';

/// Notificações de FERIADO: avisa na véspera de cada feriado nacional
/// ("Amanhã é feriado 🎉"). Tudo local, sem servidor.
class NotifService {
  NotifService._();
  static final NotifService instance = NotifService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));
    }
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(const InitializationSettings(android: android));
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    _ready = true;
  }

  /// (Re)agenda os avisos dos próximos feriados nacionais. Chame no startup.
  Future<void> scheduleHolidayReminders() async {
    if (!_ready) await init();
    await _plugin.cancelAll();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final pool = [
      ...Holidays.forYear(now.year),
      ...Holidays.forYear(now.year + 1),
    ]..sort((a, b) => a.date.compareTo(b.date));
    final upcoming = pool
        .where((h) => h.isNacional && !h.date.isBefore(today))
        .take(12)
        .toList();

    var id = 100;
    for (final h in upcoming) {
      // Véspera às 18:00.
      final eve = DateTime(h.date.year, h.date.month, h.date.day - 1, 18, 0);
      if (eve.isAfter(now)) {
        await _schedule(
            id++, 'Amanhã é feriado', h.name, eve);
      }
    }
  }

  Future<void> _schedule(
      int id, String title, String body, DateTime when) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(when, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'feriados',
          'Feriados',
          channelDescription: 'Avisos na véspera dos feriados',
          importance: Importance.high,
          priority: Priority.high,
          // Ícone pequeno (status bar) + ícone colorido do app (largeIcon),
          // para a notificação aparecer SEMPRE com a identidade do app.
          icon: '@mipmap/ic_launcher',
          largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Agenda (ou reagenda) a notificação de um evento pessoal.
  Future<void> scheduleEvent(CalendarEvent e) async {
    if (!_ready) await init();
    await _plugin.cancel(e.id);
    if (!e.notify) return;
    final when = e.when;
    if (!when.isAfter(DateTime.now())) return;
    final body = e.hasTime ? '${e.timeLabel} · ${e.title}' : e.title;
    await _schedule(e.id, '🔔 Lembrete', body, when);
  }

  Future<void> cancelEvent(int id) async {
    if (!_ready) await init();
    await _plugin.cancel(id);
  }

  Future<void> cancelAll() async => _plugin.cancelAll();
}
