/// Evento/lembrete pessoal do usuário em um dia do calendário.
class CalendarEvent {
  CalendarEvent({
    required this.id,
    required this.date,
    required this.title,
    this.hour,
    this.minute,
    this.notify = true,
  });

  /// Id estável (usado também como id da notificação).
  final int id;

  /// Dia do evento (sem hora).
  final DateTime date;

  String title;
  int? hour;
  int? minute;
  bool notify;

  bool get hasTime => hour != null && minute != null;

  String get timeLabel => hasTime
      ? '${hour!.toString().padLeft(2, '0')}:${minute!.toString().padLeft(2, '0')}'
      : '';

  /// Chave do dia (yyyy-MM-dd) para agrupar/persistir.
  static String keyOf(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String get dayKey => keyOf(date);

  /// Momento do disparo da notificação (data + hora, ou 09:00 por padrão).
  DateTime get when =>
      DateTime(date.year, date.month, date.day, hour ?? 9, minute ?? 0);

  Map<String, dynamic> toJson() => {
        'id': id,
        'd': date.millisecondsSinceEpoch,
        't': title,
        'h': hour,
        'm': minute,
        'n': notify,
      };

  factory CalendarEvent.fromJson(Map<String, dynamic> j) => CalendarEvent(
        id: j['id'] as int,
        date: DateTime.fromMillisecondsSinceEpoch(j['d'] as int),
        title: j['t'] as String,
        hour: j['h'] as int?,
        minute: j['m'] as int?,
        notify: (j['n'] as bool?) ?? true,
      );
}
