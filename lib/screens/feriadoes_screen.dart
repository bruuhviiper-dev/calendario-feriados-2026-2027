import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/long_weekends.dart';
import '../widgets/banner_ad.dart';
import '../widgets/theme_toggle.dart';

/// Feriadões / Emendas: fins de semana prolongados do ano, com fotos reais
/// (clima de viagem) e sugestão de emenda.
class FeriadoesScreen extends StatefulWidget {
  const FeriadoesScreen({super.key});
  @override
  State<FeriadoesScreen> createState() => _FeriadoesScreenState();
}

class _FeriadoesScreenState extends State<FeriadoesScreen> {
  late int _year = DateTime.now().year;

  static const _weekdays = ['dom', 'seg', 'ter', 'qua', 'qui', 'sex', 'sáb'];
  static const _months = [
    'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
    'jul', 'ago', 'set', 'out', 'nov', 'dez'
  ];
  // Fotos reais curadas (paisagens/praias/viagem, sem pessoas) — Lorem Picsum.
  static const _photos = [
    1016, 1015, 1018, 1036, 1039, 1043, 1044, 1047, 1051, 1053, 1057, 1061,
  ];

  String _fmt(DateTime d) => '${_weekdays[d.weekday % 7]} ${d.day}/${d.month}';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final all = LongWeekend.forYear(_year);
    // Os que valem (auto + emenda + meio de semana), descartando os perdidos.
    final good = all.where((l) => l.kind != LwKind.weekend).toList();

    return Scaffold(
      bottomNavigationBar: const BannerPlaceholder(),
      appBar: AppBar(
        title: const Text('Feriadões'),
        actions: [
          const ThemeToggleButton(),
          IconButton(
            tooltip: 'Ano anterior',
            onPressed: () => setState(() => _year--),
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Center(
              child: Text('$_year',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16))),
          IconButton(
            tooltip: 'Próximo ano',
            onPressed: () => setState(() => _year++),
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
        children: [
          Text('${good.length} feriadões em $_year',
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.w800)),
          Text('Fins de semana prolongados e emendas que valem a pena.',
              style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.6))),
          const SizedBox(height: 14),
          for (var i = 0; i < good.length; i++) ...[
            _card(good[i], i, scheme),
            if (i == 2) const MediumRectangleAd(),
          ],
        ],
      ),
    );
  }

  Widget _card(LongWeekend lw, int i, ColorScheme scheme) {
    final h = lw.holiday;
    final photo = _photos[i % _photos.length];
    final badgeColor = switch (lw.kind) {
      LwKind.auto => const Color(0xFF16A34A),
      LwKind.bridge => const Color(0xFFF59E0B),
      LwKind.midweek => const Color(0xFF6366F1),
      LwKind.weekend => Colors.grey,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          // ---- foto real + faixa ----
          Stack(
            children: [
              CachedNetworkImage(
                imageUrl: 'https://picsum.photos/id/$photo/800/360',
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, _) => Container(
                    height: 150, color: scheme.surfaceContainerHighest),
                errorWidget: (_, _, _) => Container(
                    height: 150,
                    decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                      scheme.primary,
                      scheme.primary.withValues(alpha: 0.6)
                    ]))),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.72)],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(lw.badge,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800)),
                ),
              ),
              Positioned(
                bottom: 10,
                left: 14,
                right: 14,
                child: Row(
                  children: [
                    Icon(h.icon, color: Colors.white, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(h.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              shadows: [
                                Shadow(color: Colors.black54, blurRadius: 8)
                              ])),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${lw.totalDays}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                height: 1)),
                        const Text('dias',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          // ---- detalhe ----
          Container(
            width: double.infinity,
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.beach_access_rounded,
                        size: 18, color: scheme.primary),
                    const SizedBox(width: 8),
                    Text(
                        'Folga: ${_fmt(lw.start)} a ${_fmt(lw.end)} de ${_months[lw.end.month - 1]}',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                if (lw.bridges.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.lightbulb_rounded,
                          size: 18, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                            'Emende: ${lw.bridges.map((b) => '${_weekdays[b.weekday % 7]} ${b.day}/${b.month}').join(' e ')}',
                            style: const TextStyle(color: Colors.grey)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
