/// Motor de FERIADOS nacionais do Brasil — 100% algorítmico (auto-atualiza pra
/// qualquer ano). Feriados fixos + móveis calculados a partir da Páscoa
/// (algoritmo de Computus / Meeus-Jones-Butcher, calendário gregoriano).
library;

enum HolidayType { nacional, facultativo }

class Holiday {
  const Holiday(this.date, this.name, this.type, {this.emoji = '📅'});
  final DateTime date;
  final String name;
  final HolidayType type;
  final String emoji;

  bool get isNacional => type == HolidayType.nacional;
}

class Holidays {
  Holidays._();

  /// Domingo de Páscoa do [year] (gregoriano) — Meeus/Jones/Butcher.
  static DateTime easter(int year) {
    final a = year % 19;
    final b = year ~/ 100;
    final c = year % 100;
    final d = b ~/ 4;
    final e = b % 4;
    final f = (b + 8) ~/ 25;
    final g = (b - f + 1) ~/ 3;
    final h = (19 * a + b - d - g + 15) % 30;
    final i = c ~/ 4;
    final k = c % 4;
    final l = (32 + 2 * e + 2 * i - h - k) % 7;
    final m = (a + 11 * h + 22 * l) ~/ 451;
    final month = (h + l - 7 * m + 114) ~/ 31;
    final day = ((h + l - 7 * m + 114) % 31) + 1;
    return DateTime(year, month, day);
  }

  static DateTime _add(DateTime d, int days) => d.add(Duration(days: days));

  /// Todos os feriados/pontos facultativos NACIONAIS do [year], ordenados.
  static List<Holiday> forYear(int year) {
    final pascoa = easter(year);
    final list = <Holiday>[
      // ---- FIXOS (nacionais) ----
      Holiday(DateTime(year, 1, 1), 'Confraternização Universal',
          HolidayType.nacional, emoji: '🎉'),
      Holiday(DateTime(year, 4, 21), 'Tiradentes', HolidayType.nacional,
          emoji: '⚖️'),
      Holiday(DateTime(year, 5, 1), 'Dia do Trabalho', HolidayType.nacional,
          emoji: '💼'),
      Holiday(DateTime(year, 9, 7), 'Independência do Brasil',
          HolidayType.nacional, emoji: '🇧🇷'),
      Holiday(DateTime(year, 10, 12), 'Nossa Senhora Aparecida',
          HolidayType.nacional, emoji: '🙏'),
      Holiday(DateTime(year, 11, 2), 'Finados', HolidayType.nacional,
          emoji: '🕯️'),
      Holiday(DateTime(year, 11, 15), 'Proclamação da República',
          HolidayType.nacional, emoji: '🏛️'),
      Holiday(DateTime(year, 11, 20), 'Consciência Negra',
          HolidayType.nacional, emoji: '✊🏿'),
      Holiday(DateTime(year, 12, 25), 'Natal', HolidayType.nacional,
          emoji: '🎄'),
      // ---- MÓVEIS a partir da Páscoa ----
      Holiday(_add(pascoa, -2), 'Sexta-feira Santa', HolidayType.nacional,
          emoji: '✝️'),
      Holiday(pascoa, 'Páscoa', HolidayType.nacional, emoji: '🐣'),
      // ---- PONTOS FACULTATIVOS (nacionais) ----
      Holiday(_add(pascoa, -48), 'Carnaval (segunda)', HolidayType.facultativo,
          emoji: '🎭'),
      Holiday(_add(pascoa, -47), 'Carnaval', HolidayType.facultativo,
          emoji: '🎭'),
      Holiday(_add(pascoa, -46), 'Quarta-feira de Cinzas',
          HolidayType.facultativo, emoji: '✝️'),
      Holiday(_add(pascoa, 60), 'Corpus Christi', HolidayType.facultativo,
          emoji: '🍞'),
      Holiday(DateTime(year, 10, 28), 'Dia do Servidor Público',
          HolidayType.facultativo, emoji: '🏢'),
    ];
    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  /// Feriado do [day] (ignora horário), ou null. Prioriza nacional.
  static Holiday? on(DateTime day) {
    final year = day.year;
    Holiday? fac;
    for (final h in forYear(year)) {
      if (h.date.year == day.year &&
          h.date.month == day.month &&
          h.date.day == day.day) {
        if (h.isNacional) return h;
        fac ??= h;
      }
    }
    return fac;
  }

  /// Próximos [count] feriados a partir de [from] (inclui hoje), varrendo até o
  /// ano seguinte se preciso.
  static List<Holiday> next(DateTime from, {int count = 6}) {
    final today = DateTime(from.year, from.month, from.day);
    final pool = [...forYear(from.year), ...forYear(from.year + 1)];
    pool.sort((a, b) => a.date.compareTo(b.date));
    return pool.where((h) => !h.date.isBefore(today)).take(count).toList();
  }

  /// Dias entre hoje e a data (0 = hoje, 1 = amanhã...).
  static int daysUntil(DateTime from, DateTime target) {
    final a = DateTime(from.year, from.month, from.day);
    final b = DateTime(target.year, target.month, target.day);
    return b.difference(a).inDays;
  }
}
