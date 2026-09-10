import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/app_info.dart';
import '../data/app_theme.dart';
import '../services/app_state.dart';
import '../services/notif_service.dart';
import '../widgets/banner_ad.dart';
import 'appearance_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    final apps = AppInfo.otherApps;
    return Scaffold(
      bottomNavigationBar: const BannerPlaceholder(),
      appBar: AppBar(title: const Text('Mais')),
      body: ListView(
        children: [
          Consumer<AppState>(
            builder: (c, s, _) => SwitchListTile(
              secondary: const Icon(Icons.notifications_active_rounded,
                  color: Color(0xFF2563EB)),
              title: const Text('Avisar dos feriados'),
              subtitle: const Text('Notifica na véspera de cada feriado 🎉'),
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
          ListTile(
            leading: const Icon(Icons.palette_rounded, color: Color(0xFF7C3AED)),
            title: const Text('Aparência e temas'),
            subtitle: const Text('Modo escuro e cores do app 🎨'),
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AppearanceScreen())),
          ),
          Consumer<AppState>(
            builder: (c, s, _) => s.adsRemoved
                ? const SizedBox.shrink()
                : ListTile(
                    leading: const Icon(Icons.block_rounded,
                        color: Color(0xFFEF4444)),
                    title: const Text('Remover anúncios'),
                    subtitle: const Text('Compra única • libera os temas 🚫'),
                    onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const StoreScreen())),
                  ),
          ),
          ListTile(
            leading: const Icon(Icons.star_rounded, color: Color(0xFFFBBF24)),
            title: const Text('Avaliar na Play Store'),
            subtitle: const Text('Sua nota ajuda muito 💛'),
            onTap: () => _open(AppInfo.playUrl),
          ),
          ListTile(
            leading: const Icon(Icons.ios_share_rounded),
            title: const Text('Compartilhar o app'),
            subtitle: const Text('Indique para os amigos'),
            onTap: () =>
                Share.share('Conheça o ${AppInfo.appName}! ${AppInfo.playUrl}'),
          ),
          const SizedBox(height: 8),
          // ---- Cross-promoção em destaque ----
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 2),
            child: Row(
              children: [
                const Text('✨', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text('Mais apps da Phantom',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text('Todos grátis. Toque para conhecer 👇',
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Material(
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        child: Ink(
          decoration: BoxDecoration(
            gradient: AppTheme.gradient(gradient),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: gradient.last.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 6)),
            ],
          ),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: Text(emoji, style: const TextStyle(fontSize: 24)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          shadows: [
                            Shadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 1)),
                          ],
                        )),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Abrir',
                            style: TextStyle(
                                color: gradient.last,
                                fontSize: 13,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded,
                            size: 15, color: gradient.last),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
