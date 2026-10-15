import 'package:flutter/material.dart';

import '../widgets/banner_ad.dart';

/// Ferramentas de data: dias entre duas datas + somar/subtrair dias.
class DateToolsScreen extends StatefulWidget {
  const DateToolsScreen({super.key});
  @override
  State<DateToolsScreen> createState() => _DateToolsScreenState();
}

class _DateToolsScreenState extends State<DateToolsScreen> {
  static const _wd = ['', 'segunda', 'terça', 'quarta', 'quinta', 'sexta', 'sábado', 'domingo'];
  static const _wd2 = ['dom', 'seg', 'ter', 'qua', 'qui', 'sex', 'sáb'];

  // diferença entre datas
  DateTime _a = DateTime.now();
  DateTime _b = DateTime.now().add(const Duration(days: 30));
  // somar/subtrair
  DateTime _base = DateTime.now();
  int _delta = 30;

  String _fmt(DateTime d) =>
      '${_wd2[d.weekday % 7]} ${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<DateTime?> _pick(DateTime initial) => showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100));

  (int, int, int) _ymd(DateTime a, DateTime b) {
    if (b.isBefore(a)) {
      final t = a;
      a = b;
      b = t;
    }
    var y = b.year - a.year;
    var m = b.month - a.month;
    var d = b.day - a.day;
    if (d < 0) {
      m--;
      d += DateTime(b.year, b.month, 0).day;
    }
    if (m < 0) {
      y--;
      m += 12;
    }
    return (y, m, d);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final days = _b.difference(DateTime(_a.year, _a.month, _a.day)).inDays.abs();
    final weeks = days ~/ 7;
    final (yy, mm, dd) = _ymd(_a, _b);
    final result = DateTime(_base.year, _base.month, _base.day)
        .add(Duration(days: _delta));

    return Scaffold(
      bottomNavigationBar: const BannerPlaceholder(),
      appBar: AppBar(title: const Text('Ferramentas de data')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---- Dias entre datas ----
          _title('Dias entre duas datas', Icons.date_range_rounded, scheme),
          Row(
            children: [
              Expanded(child: _dateBtn('De', _a, (d) => setState(() => _a = d))),
              const SizedBox(width: 10),
              Expanded(child: _dateBtn('Até', _b, (d) => setState(() => _b = d))),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                scheme.primary,
                scheme.primary.withValues(alpha: 0.7)
              ]),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                Text('$days',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 46,
                        fontWeight: FontWeight.w900)),
                const Text('dias',
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 6),
                Text(
                    '$weeks semanas · ${yy > 0 ? '$yy ano(s), ' : ''}$mm mês(es) e $dd dia(s)',
                    style: const TextStyle(color: Colors.white, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 26),
          // ---- Somar/subtrair ----
          _title('Somar ou subtrair dias', Icons.calculate_rounded, scheme),
          _dateBtn('Data base', _base, (d) => setState(() => _base = d)),
          const SizedBox(height: 10),
          Row(
            children: [
              IconButton.filledTonal(
                  onPressed: () => setState(() => _delta -= 1),
                  icon: const Icon(Icons.remove_rounded)),
              Expanded(
                child: Column(
                  children: [
                    Text(_delta >= 0 ? '+$_delta dias' : '$_delta dias',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800)),
                    Slider(
                      min: -365,
                      max: 365,
                      value: _delta.toDouble().clamp(-365, 365),
                      onChanged: (v) => setState(() => _delta = v.round()),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                  onPressed: () => setState(() => _delta += 1),
                  icon: const Icon(Icons.add_rounded)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                Text('${result.day.toString().padLeft(2, '0')}/${result.month.toString().padLeft(2, '0')}/${result.year}',
                    style: const TextStyle(
                        fontSize: 30, fontWeight: FontWeight.w900)),
                Text('${_wd[result.weekday]}-feira'
                    .replaceAll('sábado-feira', 'sábado')
                    .replaceAll('domingo-feira', 'domingo'),
                    style: TextStyle(color: scheme.primary, fontSize: 15)),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _title(String t, IconData i, ColorScheme scheme) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Icon(i, color: scheme.primary),
            const SizedBox(width: 8),
            Text(t,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          ],
        ),
      );

  Widget _dateBtn(String label, DateTime d, ValueChanged<DateTime> onPick) =>
      OutlinedButton(
        onPressed: () async {
          final r = await _pick(d);
          if (r != null) onPick(r);
        },
        style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12)),
        child: Column(
          children: [
            Text(label,
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
            Text(_fmt(d),
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      );
}
