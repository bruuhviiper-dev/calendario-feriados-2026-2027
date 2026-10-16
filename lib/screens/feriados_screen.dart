import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/holidays.dart';
import '../widgets/banner_ad.dart';
import '../widgets/state_chip.dart';
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
          // ---- Meu estado (chip em destaque) ----
          const StateChip(margin: EdgeInsets.fromLTRB(16, 12, 16, 0)),
          // ---- Próximos feriados (destaque) ----
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 10, 18, 8),
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
    // Cores vívidas e fixas (não dependem do tema) para o card se destacar
    // bem — azul→índigo nos nacionais, ardósia nos facultativos.
    final c1 = h.isNacional ? const Color(0xFF2563EB) : const Color(0xFF64748B);
    final c2 = h.isNacional ? const Color(0xFF4F46E5) : const Color(0xFF475569);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [c1, c2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
              color: c1.withValues(alpha: 0.42),
              blurRadius: 20,
              offset: const Offset(0, 8)),
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(_countdown(days),
                style: TextStyle(
                    color: c1,
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
