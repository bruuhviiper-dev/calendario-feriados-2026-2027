import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/holidays.dart';
import '../widgets/banner_ad.dart';

/// Tela principal: grade do mês + feriados do mês. Navega mês a mês e volta pra
/// "hoje". Os feriados são calculados na hora (qualquer ano).
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final _today = DateTime.now();
  late DateTime _month = DateTime(_today.year, _today.month);
  DateTime? _selected;

  static const _weekdays = ['dom', 'seg', 'ter', 'qua', 'qui', 'sex', 'sáb'];
  static const _months = [
    'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
    'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
  ];

  void _go(int delta) =>
      setState(() => _month = DateTime(_month.year, _month.month + delta));
  void _goToday() => setState(() {
        _month = DateTime(_today.year, _today.month);
        _selected = DateTime(_today.year, _today.month, _today.day);
      });

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final first = DateTime(_month.year, _month.month, 1);
    final lead = first.weekday % 7; // domingo = 0
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final cells = <DateTime?>[
      ...List.filled(lead, null),
      for (var d = 1; d <= daysInMonth; d++)
        DateTime(_month.year, _month.month, d),
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }

    final monthHolidays = Holidays.forYear(_month.year)
        .where((h) => h.date.month == _month.month)
        .toList();

    return Scaffold(
      bottomNavigationBar: const BannerPlaceholder(),
      appBar: AppBar(
        title: const Text('Calendário'),
        actions: [
          TextButton.icon(
            onPressed: _goToday,
            icon: const Icon(Icons.today_rounded, size: 18),
            label: const Text('Hoje'),
          ),
        ],
      ),
      body: ListView(
        children: [
          // ---- cabeçalho do mês ----
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Row(
              children: [
                IconButton(
                    onPressed: () => _go(-1),
                    icon: const Icon(Icons.chevron_left_rounded)),
                Expanded(
                  child: Text(
                    '${_months[_month.month - 1]} ${_month.year}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                        fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                    onPressed: () => _go(1),
                    icon: const Icon(Icons.chevron_right_rounded)),
              ],
            ),
          ),
          // ---- dias da semana ----
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: Center(
                      child: Text(_weekdays[i],
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: (i == 0 || i == 6)
                                  ? scheme.primary
                                  : scheme.onSurface.withValues(alpha: 0.6))),
                    ),
                  ),
              ],
            ),
          ),
          // ---- grade ----
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
            child: GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [for (final d in cells) _dayCell(d, scheme)],
            ),
          ),
          // ---- detalhe do dia selecionado ----
          if (_selected != null) _selectedInfo(scheme),
          const Divider(height: 24),
          // ---- feriados do mês ----
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 6),
            child: Text('Feriados em ${_months[_month.month - 1]}',
                style: Theme.of(context).textTheme.titleMedium),
          ),
          if (monthHolidays.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 4, 18, 16),
              child: Text('Nenhum feriado neste mês.',
                  style: TextStyle(color: Colors.grey)),
            )
          else
            for (final h in monthHolidays) _holidayTile(h, scheme),
          const SizedBox(height: 12),
          _legend(scheme),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _dayCell(DateTime? d, ColorScheme scheme) {
    if (d == null) return const SizedBox.shrink();
    final holiday = Holidays.on(d);
    final isToday = _sameDay(d, _today);
    final isSel = _selected != null && _sameDay(d, _selected!);
    final isWeekend = d.weekday == DateTime.sunday || d.weekday == DateTime.saturday;

    Color? bg;
    Color fg = scheme.onSurface;
    if (holiday != null && holiday.isNacional) {
      bg = scheme.primary;
      fg = scheme.onPrimary;
    } else if (holiday != null) {
      bg = scheme.primary.withValues(alpha: 0.16);
      fg = scheme.primary;
    } else if (isWeekend) {
      fg = scheme.onSurface.withValues(alpha: 0.45);
    }

    return GestureDetector(
      onTap: () => setState(() => _selected = d),
      child: Container(
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: isSel
              ? Border.all(color: scheme.primary, width: 2)
              : isToday
                  ? Border.all(
                      color: scheme.primary.withValues(alpha: 0.6), width: 1.5)
                  : null,
        ),
        alignment: Alignment.center,
        child: Text('${d.day}',
            style: TextStyle(
                color: fg,
                fontSize: 14.5,
                fontWeight:
                    (isToday || holiday != null) ? FontWeight.w800 : FontWeight.w500)),
      ),
    );
  }

  Widget _selectedInfo(ColorScheme scheme) {
    final d = _selected!;
    final h = Holidays.on(d);
    final label =
        '${_weekdays[d.weekday % 7]}, ${d.day} de ${_months[d.month - 1].toLowerCase()}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Text(h?.emoji ?? '📆', style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 12.5, color: Colors.grey)),
                  Text(
                    h == null
                        ? 'Dia comum'
                        : '${h.name}${h.isNacional ? '' : ' (ponto facultativo)'}',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: h != null ? scheme.primary : null),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _holidayTile(Holiday h, ColorScheme scheme) {
    return ListTile(
      dense: true,
      leading: Text(h.emoji, style: const TextStyle(fontSize: 22)),
      title: Text(h.name,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
          '${_weekdays[h.date.weekday % 7]}, dia ${h.date.day}'
          '${h.isNacional ? '' : ' · facultativo'}'),
      trailing: h.isNacional
          ? Icon(Icons.event_available_rounded, color: scheme.primary)
          : const Icon(Icons.event_note_rounded, color: Colors.grey),
    );
  }

  Widget _legend(ColorScheme scheme) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(
          children: [
            _dot(scheme.primary), const Text('  Feriado nacional   '),
            _dot(scheme.primary.withValues(alpha: 0.16)),
            const Text('  Facultativo'),
          ],
        ),
      );

  Widget _dot(Color c) => Container(
      width: 14, height: 14, decoration: BoxDecoration(color: c, shape: BoxShape.circle));
}
