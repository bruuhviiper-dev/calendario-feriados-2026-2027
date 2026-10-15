import 'holidays.dart';

enum LwKind { auto, bridge, midweek, weekend }

/// Um "feriadão": o bloco de dias de folga que um feriado proporciona,
/// com a(s) emenda(s) sugerida(s).
class LongWeekend {
  LongWeekend({
    required this.holiday,
    required this.kind,
    required this.start,
    required this.end,
    required this.bridges,
  });

  final Holiday holiday;
  final LwKind kind;
  final DateTime start; // 1º dia de folga
  final DateTime end; // último dia de folga
  final List<DateTime> bridges; // dias de emenda (úteis que você tira)

  int get totalDays => end.difference(start).inDays + 1;

  String get badge => switch (kind) {
        LwKind.auto => 'Fim de semana prolongado',
        LwKind.bridge => 'Vale a pena emendar',
        LwKind.midweek => 'No meio da semana',
        LwKind.weekend => 'Cai no fim de semana',
      };

  /// Analisa todos os feriados NACIONAIS do ano e devolve os feriadões,
  /// ordenados por data.
  static List<LongWeekend> forYear(int year) {
    final out = <LongWeekend>[];
    for (final h in Holidays.forYear(year)) {
      if (!h.isNacional) continue;
      final d = h.date;
      final wd = d.weekday; // Mon=1 ... Sun=7
      switch (wd) {
        case DateTime.saturday:
        case DateTime.sunday:
          // Perde a folga (já é fim de semana).
          final satSun = wd == DateTime.saturday
              ? [d, d.add(const Duration(days: 1))]
              : [d.subtract(const Duration(days: 1)), d];
          out.add(LongWeekend(
              holiday: h,
              kind: LwKind.weekend,
              start: satSun.first,
              end: satSun.last,
              bridges: const []));
          break;
        case DateTime.monday:
          out.add(LongWeekend(
              holiday: h,
              kind: LwKind.auto,
              start: d.subtract(const Duration(days: 2)), // sáb
              end: d,
              bridges: const []));
          break;
        case DateTime.friday:
          out.add(LongWeekend(
              holiday: h,
              kind: LwKind.auto,
              start: d,
              end: d.add(const Duration(days: 2)), // dom
              bridges: const []));
          break;
        case DateTime.tuesday:
          final mon = d.subtract(const Duration(days: 1));
          out.add(LongWeekend(
              holiday: h,
              kind: LwKind.bridge,
              start: d.subtract(const Duration(days: 3)), // sáb
              end: d,
              bridges: [mon]));
          break;
        case DateTime.thursday:
          final fri = d.add(const Duration(days: 1));
          out.add(LongWeekend(
              holiday: h,
              kind: LwKind.bridge,
              start: d,
              end: d.add(const Duration(days: 3)), // dom
              bridges: [fri]));
          break;
        case DateTime.wednesday:
          // Emenda 2 dias (qui+sex) → 5 dias de folga.
          out.add(LongWeekend(
              holiday: h,
              kind: LwKind.midweek,
              start: d,
              end: d.add(const Duration(days: 4)), // dom
              bridges: [
                d.add(const Duration(days: 1)),
                d.add(const Duration(days: 2))
              ]));
          break;
      }
    }
    out.sort((a, b) => a.holiday.date.compareTo(b.holiday.date));
    return out;
  }
}
