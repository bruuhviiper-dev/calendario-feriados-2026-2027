import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/holidays.dart';
import '../widgets/banner_ad.dart';
import '../widgets/theme_toggle.dart';

/// Próximos feriados (com contagem regressiva) + lista completa do ano,
/// com seletor de ano (qualquer ano). Tudo calculado na hora.
class FeriadosScreen extends StatefulWidget {
  const FeriadosScreen({super.key});

  @override
  State<FeriadosScreen> createState() => _FeriadosScreenState();
}

class _FeriadosScreenState extends State<FeriadosScreen> {
  final _today = DateTime.now();
  late int _year = DateTime.now().year;

  static const _weekdays = ['dom', 'seg', 'ter', 'qua', 'qui', 'sex', 'sáb'];
  static const _months = [
    'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
    'jul', 'ago', 'set', 'out', 'nov', 'dez'
  ];

  String _countdown(int days) {
    if (days == 0) return 'Hoje!';
    if (days == 1) return 'Amanhã';
    return 'Faltam $days dias';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final next = Holidays.next(_today, count: 4);
    final yearList = Holidays.forYear(_year);

    return Scaffold(
      bottomNavigationBar: const BannerPlaceholder(),
      appBar: AppBar(
        title: const Text('Feriados'),
        actions: const [ThemeToggleButton()],
      ),
      body: ListView(
        children: [
          // ---- Próximos feriados (destaque) ----
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 14, 18, 8),
            child: Text('Próximos feriados',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          ),
          for (final h in next) _nextCard(h, scheme),
          const MediumRectangleAd(),
          const Divider(height: 30),
          // ---- Seletor de ano ----
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                IconButton(
                    onPressed: () => setState(() => _year--),
                    icon: const Icon(Icons.chevron_left_rounded)),
                Expanded(
                  child: Text('Feriados de $_year',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                          fontSize: 18, fontWeight: FontWeight.w800)),
                ),
                IconButton(
                    onPressed: () => setState(() => _year++),
                    icon: const Icon(Icons.chevron_right_rounded)),
              ],
            ),
          ),
          const SizedBox(height: 4),
          for (var i = 0; i < yearList.length; i++) ...[
            _yearTile(yearList[i], scheme),
            if (i == 5) const MediumRectangleAd(),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _nextCard(Holiday h, ColorScheme scheme) {
    final days = Holidays.daysUntil(_today, h.date);
    final wd = _weekdays[h.date.weekday % 7];
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: h.isNacional
              ? [scheme.primary, scheme.primary.withValues(alpha: 0.75)]
              : [Colors.grey.shade600, Colors.grey.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: scheme.primary.withValues(alpha: 0.25),
              blurRadius: 14,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(h.icon, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(h.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(
                    '$wd, ${h.date.day} de ${_months[h.date.month - 1]}'
                    '${h.isNacional ? '' : ' · facultativo'}',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(_countdown(days),
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5)),
          ),
        ],
      ),
    );
  }

  Widget _yearTile(Holiday h, ColorScheme scheme) {
    final wd = _weekdays[h.date.weekday % 7];
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: h.isNacional
            ? scheme.primary.withValues(alpha: 0.15)
            : Colors.grey.withValues(alpha: 0.15),
        child: Icon(h.icon,
            size: 20, color: h.isNacional ? scheme.primary : Colors.grey),
      ),
      title: Text(h.name,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('$wd, ${h.date.day} de ${_months[h.date.month - 1]}'
          '${h.isNacional ? '' : ' · ponto facultativo'}'),
      trailing: Text(
        '${h.date.day.toString().padLeft(2, '0')}/${h.date.month.toString().padLeft(2, '0')}',
        style: TextStyle(
            fontWeight: FontWeight.w800,
            color: h.isNacional ? scheme.primary : Colors.grey),
      ),
    );
  }
}
