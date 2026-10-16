/// Motor de FERIADOS nacionais do Brasil — 100% algorítmico (auto-atualiza pra
/// qualquer ano). Feriados fixos + móveis calculados a partir da Páscoa
/// (algoritmo de Computus / Meeus-Jones-Butcher, calendário gregoriano).
library;

import 'package:flutter/material.dart';

enum HolidayType { nacional, facultativo, estadual }

class Holiday {
  const Holiday(this.date, this.name, this.type, {this.emoji = '📅'});
  final DateTime date;
  final String name;
  final HolidayType type;
  final String emoji;

  bool get isNacional => type == HolidayType.nacional;
  bool get isEstadual => type == HolidayType.estadual;

  /// Ícone limpo (Material) por tipo — visual sóbrio no lugar dos emojis.
  IconData get icon => switch (type) {
        HolidayType.nacional => Icons.flag_rounded,
        HolidayType.estadual => Icons.location_city_rounded,
        HolidayType.facultativo => Icons.event_available_rounded,
      };
}

class Holidays {
  Holidays._();

  /// UF selecionada pelo usuário ('' = nenhum). Quando definida, os feriados
  /// estaduais correspondentes entram em [forYear]/[on]. Setada pelo AppState.
  static String selectedUf = '';

  /// Nome dos estados (código → nome), para o seletor.
  static const ufNames = <String, String>{
    'AC': 'Acre', 'AL': 'Alagoas', 'AP': 'Amapá', 'AM': 'Amazonas',
    'BA': 'Bahia', 'CE': 'Ceará', 'DF': 'Distrito Federal', 'MA': 'Maranhão',
    'MS': 'Mato Grosso do Sul', 'MG': 'Minas Gerais', 'PA': 'Pará',
    'PB': 'Paraíba', 'PR': 'Paraná', 'PE': 'Pernambuco', 'PI': 'Piauí',
    'RJ': 'Rio de Janeiro', 'RN': 'Rio Grande do Norte',
    'RS': 'Rio Grande do Sul', 'RO': 'Rondônia', 'RR': 'Roraima',
    'SP': 'São Paulo', 'SE': 'Sergipe', 'TO': 'Tocantins',
  };

  /// Feriados estaduais fixos (mês, dia, nome, emoji) por UF. Só datas fixas
  /// amplamente reconhecidas (feriado civil estadual).
  static const _stateData = <String, List<List<Object>>>{
    'AC': [[6, 15, 'Aniversário do Acre', '🌳'], [9, 5, 'Dia da Amazônia', '🌳']],
    'AL': [[9, 16, 'Emancipação de Alagoas', '🎗️']],
    'AP': [[9, 13, 'Criação do Amapá', '🎗️']],
    'AM': [[9, 5, 'Elevação do Amazonas', '🌳']],
    'BA': [[7, 2, 'Independência da Bahia', '🎉']],
    'CE': [[3, 25, 'Data Magna do Ceará', '⛓️']],
    'DF': [[4, 21, 'Fundação de Brasília', '🏛️'], [11, 30, 'Dia do Evangélico', '🙏']],
    'MA': [[7, 28, 'Adesão do Maranhão', '🎉']],
    'MS': [[10, 11, 'Criação de Mato Grosso do Sul', '🎗️']],
    'MG': [[12, 8, 'Imaculada Conceição (MG)', '🙏']],
    'PA': [[8, 15, 'Adesão do Pará', '🎉']],
    'PB': [[8, 5, 'Fundação da Paraíba', '🎗️']],
    'PR': [[12, 19, 'Emancipação do Paraná', '🎗️']],
    'PE': [[3, 6, 'Revolução Pernambucana', '🎖️']],
    'PI': [[10, 19, 'Dia do Piauí', '🎗️']],
    'RJ': [[4, 23, 'São Jorge', '🐉']],
    'RN': [[8, 7, 'Dia do Rio Grande do Norte', '🎗️']],
    'RS': [[9, 20, 'Revolução Farroupilha', '🐎']],
    'RO': [[1, 4, 'Criação de Rondônia', '🎗️']],
    'RR': [[10, 5, 'Criação de Roraima', '🎗️']],
    'SP': [[7, 9, 'Revolução Constitucionalista', '🎖️']],
    'SE': [[7, 8, 'Emancipação de Sergipe', '🎗️']],
    'TO': [[10, 5, 'Criação do Tocantins', '🎗️']],
  };

  static List<Holiday> _stateHolidays(int year, String uf) {
    final rows = _stateData[uf];
    if (rows == null) return const [];
    return [
      for (final r in rows)
        Holiday(DateTime(year, r[0] as int, r[1] as int), r[2] as String,
            HolidayType.estadual, emoji: r[3] as String),
    ];
  }

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
      // ---- ESTADUAIS (se o usuário escolheu um estado) ----
      if (selectedUf.isNotEmpty) ..._stateHolidays(year, selectedUf),
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
