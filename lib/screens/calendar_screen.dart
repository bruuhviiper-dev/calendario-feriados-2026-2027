import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../data/calendar_event.dart';
import '../data/holidays.dart';
import '../services/app_state.dart';
import '../services/notif_service.dart';
import '../widgets/banner_ad.dart';
import '../widgets/state_chip.dart';
import '../widgets/theme_toggle.dart';

/// Tela principal: contagem pro próximo feriado + grade do mês (feriados e
/// eventos pessoais) + detalhe do dia com lembretes. Qualquer ano.
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

  Holiday? _nextHoliday() {
    final today = DateTime(_today.year, _today.month, _today.day);
    final pool = [
      ...Holidays.forYear(_today.year),
      ...Holidays.forYear(_today.year + 1),
    ]..sort((a, b) => a.date.compareTo(b.date));
    for (final h in pool) {
      if (h.isNacional && !h.date.isBefore(today)) return h;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final state = context.watch<AppState>();
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
          const ThemeToggleButton(),
        ],
      ),
      body: ListView(
        children: [
          const StateChip(margin: EdgeInsets.fromLTRB(14, 12, 14, 2)),
          _countdownCard(scheme),
          // ---- cabeçalho do mês ----
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
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
              children: [for (final d in cells) _dayCell(d, scheme, state)],
            ),
          ),
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
          // espaço para a legenda não ficar atrás do FAB "+ Evento"
          const SizedBox(height: 100),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openDay(_selected ?? _today),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Evento'),
      ),
    );
  }

  Widget _countdownCard(ColorScheme scheme) {
    final h = _nextHoliday();
    if (h == null) return const SizedBox.shrink();
    final today = DateTime(_today.year, _today.month, _today.day);
    final days = h.date.difference(today).inDays;
    final label = days == 0
        ? 'É hoje!'
        : days == 1
            ? 'Amanhã'
            : 'Faltam $days dias';
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 14, 14, 2),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [scheme.primary, scheme.primary.withValues(alpha: 0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: scheme.onPrimary.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(h.icon, color: scheme.onPrimary, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Próximo feriado',
                    style: TextStyle(
                        color: scheme.onPrimary.withValues(alpha: 0.85),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600)),
                Text(h.name,
                    style: TextStyle(
                        color: scheme.onPrimary,
                        fontSize: 19,
                        fontWeight: FontWeight.w800)),
                Text(
                    '${_weekdays[h.date.weekday % 7]}, ${h.date.day} de ${_months[h.date.month - 1].toLowerCase()}',
                    style: TextStyle(
                        color: scheme.onPrimary.withValues(alpha: 0.85),
                        fontSize: 12.5)),
              ],
            ),
          ),
          Column(
            children: [
              Text('$days',
                  style: TextStyle(
                      color: scheme.onPrimary,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      height: 1)),
              Text(label == 'É hoje!' || label == 'Amanhã' ? label : 'dias',
                  style: TextStyle(
                      color: scheme.onPrimary.withValues(alpha: 0.85),
                      fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dayCell(DateTime? d, ColorScheme scheme, AppState state) {
    if (d == null) return const SizedBox.shrink();
    final holiday = Holidays.on(d);
    final isToday = _sameDay(d, _today);
    final isSel = _selected != null && _sameDay(d, _selected!);
    final isWeekend =
        d.weekday == DateTime.sunday || d.weekday == DateTime.saturday;
    final hasEvents = state.hasEventsOn(d);

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
      onTap: () {
        setState(() => _selected = d);
        _openDay(d);
      },
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
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text('${d.day}',
                style: TextStyle(
                    color: fg,
                    fontSize: 14.5,
                    fontWeight: (isToday || holiday != null)
                        ? FontWeight.w800
                        : FontWeight.w500)),
            if (hasEvents)
              Positioned(
                bottom: 2,
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: holiday != null && holiday.isNacional
                        ? scheme.onPrimary
                        : const Color(0xFFF59E0B),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ---- bottom sheet do dia ----
  void _openDay(DateTime day) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _DaySheet(day: day),
    );
  }

  Widget _holidayTile(Holiday h, ColorScheme scheme) {
    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: (h.isNacional ? scheme.primary : Colors.grey)
            .withValues(alpha: 0.14),
        child: Icon(h.icon,
            size: 19, color: h.isNacional ? scheme.primary : Colors.grey),
      ),
      title:
          Text(h.name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('${_weekdays[h.date.weekday % 7]}, dia ${h.date.day}'
          '${h.isNacional ? '' : ' · facultativo'}'),
      trailing: h.isNacional
          ? Icon(Icons.event_available_rounded, color: scheme.primary)
          : const Icon(Icons.event_note_rounded, color: Colors.grey),
      onTap: () => _openDay(h.date),
    );
  }

  Widget _legend(ColorScheme scheme) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Wrap(
          spacing: 6,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _dot(scheme.primary), const Text(' Feriado nacional  '),
            _dot(scheme.primary.withValues(alpha: 0.16)),
            const Text(' Facultativo  '),
            _dot(const Color(0xFFF59E0B)),
            const Text(' Seu evento'),
          ],
        ),
      );

  Widget _dot(Color c) => Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(color: c, shape: BoxShape.circle));
}

/// Bottom sheet com feriado + eventos do dia + adicionar/remover lembrete.
class _DaySheet extends StatelessWidget {
  const _DaySheet({required this.day});
  final DateTime day;

  static const _weekdays = ['dom', 'seg', 'ter', 'qua', 'qui', 'sex', 'sáb'];
  static const _months = [
    'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
    'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro'
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;
    final holiday = Holidays.on(day);
    final events = state.eventsOn(day);
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, 16 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_weekdays[day.weekday % 7]}, ${day.day} de ${_months[day.month - 1]} de ${day.year}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          if (holiday != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(holiday.icon, size: 22, color: scheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                        '${holiday.name}${holiday.isNacional ? '' : holiday.isEstadual ? ' (feriado estadual)' : ' (ponto facultativo)'}',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: scheme.primary)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 6),
          Text('Seus lembretes',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          if (events.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Nenhum lembrete neste dia.',
                  style: TextStyle(color: Colors.grey)),
            )
          else
            for (final e in events)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: Icon(
                    e.notify
                        ? Icons.notifications_active_rounded
                        : Icons.event_note_rounded,
                    color: scheme.primary),
                title: Text(e.title),
                subtitle: e.hasTime ? Text(e.timeLabel) : null,
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: () {
                    state.removeEvent(e);
                    NotifService.instance.cancelEvent(e.id);
                  },
                ),
              ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _addEvent(context, state),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Adicionar lembrete'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addEvent(BuildContext context, AppState state) async {
    final controller = TextEditingController();
    TimeOfDay? time;
    bool notify = true;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('Novo lembrete'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(hintText: 'Ex.: Pagar conta'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final t = await showTimePicker(
                            context: ctx,
                            initialTime: time ?? TimeOfDay.now());
                        if (t != null) setD(() => time = t);
                      },
                      icon: const Icon(Icons.schedule_rounded, size: 18),
                      label: Text(time == null
                          ? 'Horário'
                          : time!.format(ctx)),
                    ),
                  ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Notificar'),
                value: notify,
                onChanged: (v) => setD(() => notify = v),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Salvar')),
          ],
        ),
      ),
    );
    if (result == true && controller.text.trim().isNotEmpty) {
      final e = CalendarEvent(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        date: DateTime(day.year, day.month, day.day),
        title: controller.text.trim(),
        hour: time?.hour,
        minute: time?.minute,
        notify: notify,
      );
      state.addEvent(e);
      NotifService.instance.scheduleEvent(e);
    }
  }
}
