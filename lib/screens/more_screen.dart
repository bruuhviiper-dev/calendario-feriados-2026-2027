import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/app_info.dart';
import '../data/holidays.dart';
import '../services/ads_service.dart';
import '../services/app_state.dart';
import '../services/notif_service.dart';
import '../widgets/banner_ad.dart';
import '../widgets/theme_toggle.dart';
import 'appearance_screen.dart';
import 'date_tools_screen.dart';
import 'store_screen.dart';

/// Aba "Mais": lembrete diário, avaliar, compartilhar o app e cross-promoção
/// em destaque (cards coloridos) para alavancar os outros apps da Phantom.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  // Gradientes + emoji para deixar cada app com cara própria e chamativa.
  static const List<List<Color>> _grads = [
    [Color(0xFFFF758C), Color(0xFFFF7EB3)],
    [Color(0xFF667EEA), Color(0xFF764BA2)],
    [Color(0xFFF7971E), Color(0xFFFFD200)],
    [Color(0xFF11998E), Color(0xFF38EF7D)],
    [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
    [Color(0xFFEB3349), Color(0xFFF45C43)],
    [Color(0xFF2193B0), Color(0xFF6DD5ED)],
    [Color(0xFFDA22FF), Color(0xFF9733EE)],
    [Color(0xFFF12711), Color(0xFFF5AF19)],
    [Color(0xFF141E30), Color(0xFF243B55)],
    [Color(0xFF11998E), Color(0xFF38EF7D)],
    [Color(0xFFFC466B), Color(0xFF3F5EFB)],
  ];

  static const List<String> _emojis = [
    '💬', '📖', '☀️', '🔥', '💌', '🎂', '❤️', '🎤', '😂', '🌧️', '🙏', '🌱',
  ];

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _pickState(BuildContext context, AppState s) {
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

  @override
  Widget build(BuildContext context) {
    final apps = AppInfo.otherApps;
    return Scaffold(
      bottomNavigationBar: const BannerPlaceholder(),
      appBar: AppBar(
        title: const Text('Mais'),
        actions: const [ThemeToggleButton()],
      ),
      body: ListView(
        children: [
          Consumer<AppState>(
            builder: (c, s, _) => SwitchListTile(
              secondary: const Icon(Icons.notifications_active_rounded,
                  color: Color(0xFF2563EB)),
              title: const Text('Avisar dos feriados'),
              subtitle: const Text('Notifica na véspera de cada feriado'),
              value: s.reminderOn,
              onChanged: (v) {
                s.setReminder(on: v);
                if (v) {
                  NotifService.instance.init().then(
                      (_) => NotifService.instance.scheduleHolidayReminders());
                } else {
                  NotifService.instance.cancelAll();
                }
              },
            ),
          ),
          const Divider(height: 8),
          Consumer<AppState>(
            builder: (c, s, _) => ListTile(
              leading: const Icon(Icons.location_on_rounded,
                  color: Color(0xFF059669)),
              title: const Text('Meu estado (feriados estaduais)'),
              subtitle: Text(s.uf.isEmpty
                  ? 'Toque para escolher seu estado'
                  : 'Mostrando feriados de ${Holidays.ufNames[s.uf]}'),
              trailing: s.uf.isEmpty
                  ? const Icon(Icons.chevron_right_rounded)
                  : Text(s.uf,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
              onTap: () => _pickState(context, s),
            ),
          ),
          ListTile(
            leading:
                const Icon(Icons.calculate_rounded, color: Color(0xFF2563EB)),
            title: const Text('Ferramentas de data'),
            subtitle: const Text('Dias entre datas, somar/subtrair dias'),
            onTap: () {
              AdsService.instance.registerActionAndMaybeShow();
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DateToolsScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.palette_rounded, color: Color(0xFF7C3AED)),
            title: const Text('Aparência e temas'),
            subtitle: const Text('Modo escuro e cores do app'),
            onTap: () {
              AdsService.instance.registerActionAndMaybeShow();
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AppearanceScreen()));
            },
          ),
          Consumer<AppState>(
            builder: (c, s, _) => s.adsRemoved
                ? const SizedBox.shrink()
                : ListTile(
                    leading: const Icon(Icons.block_rounded,
                        color: Color(0xFFEF4444)),
                    title: const Text('Remover anúncios'),
                    subtitle: const Text('Compra única • libera os temas'),
                    onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const StoreScreen())),
                  ),
          ),
          ListTile(
            leading: const Icon(Icons.star_rounded, color: Color(0xFFFBBF24)),
            title: const Text('Avaliar na Play Store'),
            subtitle: const Text('Sua nota ajuda muito'),
            onTap: () => _open(AppInfo.playUrl),
          ),
          ListTile(
            leading: const Icon(Icons.ios_share_rounded),
            title: const Text('Compartilhar o app'),
            subtitle: const Text('Indique para os amigos'),
            onTap: () =>
                Share.share('Conheça o ${AppInfo.appName}! ${AppInfo.playUrl}'),
          ),
          const MediumRectangleAd(),
          const SizedBox(height: 8),
          // ---- Cross-promoção (visual sóbrio, estilo lista de apps) ----
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 2),
            child: Text('Mais apps da Phantom',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800)),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text('Todos grátis — toque para conhecer',
                style: TextStyle(fontSize: 12.5, color: Colors.grey)),
          ),
          for (int i = 0; i < apps.length; i++)
            _PromoCard(
              title: apps[i].$1,
              emoji: _emojis[i % _emojis.length],
              gradient: _grads[i % _grads.length],
              onTap: () => _open(AppInfo.playUrlFor(apps[i].$2)),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: OutlinedButton.icon(
              onPressed: () => _open(AppInfo.devUrl),
              icon: const Icon(Icons.storefront_rounded),
              label: const Text('Ver todos os apps na Play Store'),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text('By: ${AppInfo.developer}',
                style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard({
    required this.title,
    required this.emoji,
    required this.gradient,
    required this.onTap,
  });

  final String title;
  final String emoji;
  final List<Color> gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = gradient.first;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Material(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Ícone com um leve tom da cor do app (identidade sem exagero).
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(emoji, style: const TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: scheme.onSurface,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          )),
                      const SizedBox(height: 1),
                      Text('Grátis',
                          style: TextStyle(
                              fontSize: 12,
                              color: scheme.onSurface.withValues(alpha: 0.5))),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: scheme.onSurface.withValues(alpha: 0.35)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
