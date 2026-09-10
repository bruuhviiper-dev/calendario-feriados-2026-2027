import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_theme.dart';
import '../services/app_state.dart';
import '../services/purchase_service.dart';
import '../services/store_products.dart';

/// Loja enxuta: o único produto é "Remover anúncios" (compra única). Todo o
/// resto do app — temas, editor, marca d'água, categorias — é grátis.
class StoreScreen extends StatelessWidget {
  const StoreScreen({super.key});

  Future<void> _buy(BuildContext context, String id) async {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Processando…')));
    final res = await PurchaseService.instance.buy(id);
    if (!context.mounted) return;
    final msg = res == PurchaseResult.success
        ? 'Tudo certo! Anúncios removidos. 🎉'
        : 'Não foi possível concluir a compra.';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final price = PurchaseService.instance.priceOf(StoreProducts.removeAds.id);
    return Scaffold(
      appBar: AppBar(title: const Text('Remover anúncios')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              // Card acompanha o tema escolhido (só o estado "removido" fica
              // verde, como sinal de concluído).
              gradient: AppTheme.gradient(state.adsRemoved
                  ? const [Color(0xFF11998E), Color(0xFF38EF7D)]
                  : state.palette.gradient),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 10)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(state.adsRemoved ? '✅' : '🚫',
                    style: const TextStyle(fontSize: 40)),
                const SizedBox(height: 12),
                Text(
                    state.adsRemoved
                        ? 'Você já removeu os anúncios!'
                        : 'Use o app sem anúncios',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(
                    state.adsRemoved
                        ? 'Obrigado pelo apoio 💜 Todos os temas liberados pra sempre.'
                        : 'Pagamento único • ainda libera todos os temas 🎨',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.4,
                        fontWeight: FontWeight.w600)),
                if (!state.adsRemoved) ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: state.accentColor,
                          padding: const EdgeInsets.symmetric(vertical: 14)),
                      onPressed: () => _buy(context, StoreProducts.removeAds.id),
                      child: Text('Remover anúncios  •  $price',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          const _FreeBadge(),
        ],
      ),
    );
  }
}

/// Reforça que tudo o mais é grátis (evita a sensação de "app pago").
class _FreeBadge extends StatelessWidget {
  const _FreeBadge();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const items = [
      ('📅', 'Todos os feriados de 2026 e 2027'),
      ('🔔', 'Aviso na véspera dos feriados'),
      ('🔄', 'Sempre atualizado (qualquer ano)'),
      ('📴', 'Funciona offline, sem cadastro'),
    ];
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tudo isto é grátis',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: scheme.primary)),
          const SizedBox(height: 12),
          for (final it in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Text(it.$1, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 12),
                  Text(it.$2,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
