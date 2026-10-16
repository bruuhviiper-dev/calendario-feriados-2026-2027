import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/holidays.dart';
import '../services/app_state.dart';

/// Abre o seletor de estado (UF) em um bottom sheet. Compartilhado entre o
/// chip (Feriados/Calendário) e a aba Mais.
void showStatePicker(BuildContext context) {
  final s = context.read<AppState>();
  final ufs = Holidays.ufNames.keys.toList()
    ..sort((a, b) => Holidays.ufNames[a]!.compareTo(Holidays.ufNames[b]!));
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      builder: (ctx, scroll) => ListView(
        controller: scroll,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text('Escolha seu estado',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ),
          RadioListTile<String>(
            value: '',
            groupValue: s.uf,
            title: const Text('Nenhum (só nacionais)'),
            onChanged: (v) {
              s.setUf('');
              Navigator.pop(ctx);
            },
          ),
          for (final uf in ufs)
            RadioListTile<String>(
              value: uf,
              groupValue: s.uf,
              title: Text(Holidays.ufNames[uf]!),
              secondary: Text(uf,
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              onChanged: (v) {
                s.setUf(uf);
                Navigator.pop(ctx);
              },
            ),
        ],
      ),
    ),
  );
}

/// Chip "Meu estado" em destaque: mostra a UF escolhida (ou convite para
/// escolher) e abre o seletor ao tocar. Fica no topo de Feriados/Calendário.
class StateChip extends StatelessWidget {
  const StateChip({super.key, this.margin});

  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final uf = context.watch<AppState>().uf;
    final has = uf.isNotEmpty;
    final label = has ? Holidays.ufNames[uf]! : 'Escolher meu estado';
    return Padding(
      padding: margin ?? const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Material(
        color: scheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(30),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => showStatePicker(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_on_rounded, size: 18, color: scheme.primary),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    has ? 'Feriados de $label' : label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: scheme.primary, fontWeight: FontWeight.w700),
                  ),
                ),
                if (has) ...[
                  const SizedBox(width: 7),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(uf,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800)),
                  ),
                ],
                Icon(Icons.keyboard_arrow_down_rounded,
                    size: 20, color: scheme.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
