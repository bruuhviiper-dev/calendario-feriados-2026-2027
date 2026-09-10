import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_palettes.dart';
import '../data/app_theme.dart';
import '../services/ads_service.dart';
import '../services/app_state.dart';
import '../widgets/banner_ad.dart';
import 'store_screen.dart';

/// Aparência: modo claro/escuro (grátis) e temas de cores. A paleta clássica é
/// grátis; as premium liberam assistindo um vídeo (24h) ou removendo anúncios
/// (pra sempre). Nada bloqueia o uso do app — é só personalização.
class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const BannerPlaceholder(),
      appBar: AppBar(title: const Text('Aparência e temas')),
      body: Consumer<AppState>(
        builder: (context, state, _) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            // ---- Modo escuro (grátis) ----
            Card(
              elevation: 0,
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.4),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: SwitchListTile(
                secondary: Icon(
                    state.isDark
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                    color: state.accentColor),
                title: const Text('Modo escuro'),
                subtitle: const Text('Claro e escuro são grátis 💙'),
                value: state.isDark,
                onChanged: (_) => state.toggleTheme(),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Text('🎨', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text('Cor do tema',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w900)),
              ],
            ),
            if (state.hasTemporaryThemes) _tempBadge(context, state),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.86,
              children: [
                for (final p in AppPalettes.all)
                  _PaletteTile(
                    palette: p,
                    selected: state.palette.id == p.id,
                    locked: p.premium && !state.hasThemeAccess,
                    onTap: () {
                      if (!p.premium || state.hasThemeAccess) {
                        state.setPalette(p.id);
                      } else {
                        _showUnlock(context, state, p);
                      }
                    },
                  ),
              ],
            ),
            const SizedBox(height: 20),
            if (!state.hasThemeAccess)
              _unlockCta(context, state)
            else
              _unlockedNote(context, state),
          ],
        ),
      ),
    );
  }

  Widget _tempBadge(BuildContext context, AppState state) {
    final left = state.temporaryThemesLeft;
    final h = left == null ? 0 : left.inHours;
    final m = left == null ? 0 : left.inMinutes.remainder(60);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: state.accentColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Text('🎁', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                  'Temas liberados por vídeo — expira em ${h}h${m.toString().padLeft(2, '0')}',
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: state.accentColor)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _unlockCta(BuildContext context, AppState state) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppTheme.gradient(state.palette.gradient),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Libere todos os temas 🎨',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          const Text(
              'Assista um vídeo rápido e use por 24h — ou remova os anúncios e '
              'fique com todos pra sempre.',
              style: TextStyle(color: Colors.white, height: 1.35)),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: state.accentColor,
                  padding: const EdgeInsets.symmetric(vertical: 12)),
              onPressed: () => _watchToUnlock(context, state),
              icon: const Icon(Icons.play_circle_fill_rounded),
              label: const Text('Assistir vídeo e liberar 24h',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white70),
                  padding: const EdgeInsets.symmetric(vertical: 12)),
              onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const StoreScreen())),
              icon: const Icon(Icons.workspace_premium_rounded),
              label: const Text('Remover anúncios e liberar pra sempre'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _unlockedNote(BuildContext context, AppState state) {
    final permanent = state.adsRemoved || state.isPremium;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF11998E).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Text('✅', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
                permanent
                    ? 'Todos os temas liberados pra sempre. Obrigado pelo apoio 💙'
                    : 'Temas liberados! Aproveite enquanto durar o desbloqueio.',
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showUnlock(BuildContext context, AppState state, AppPalette p) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: AppTheme.gradient(p.gradient),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Text('Tema ${p.name}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 14),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.play_circle_fill_rounded,
                  color: Color(0xFF2563EB), size: 30),
              title: const Text('Assistir vídeo (libera 24h)'),
              subtitle: const Text('Todos os temas por 24 horas'),
              onTap: () {
                Navigator.of(ctx).pop();
                _watchToUnlock(context, state, then: p.id);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.workspace_premium_rounded,
                  color: Color(0xFFD9A406), size: 30),
              title: const Text('Remover anúncios (pra sempre)'),
              subtitle: const Text('Sem anúncios + todos os temas liberados'),
              onTap: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const StoreScreen()));
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _watchToUnlock(BuildContext context, AppState state,
      {String? then}) async {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Carregando vídeo…')));
    final ok = await AdsService.instance.showRewarded(() {
      state.grantTemporaryThemes(const Duration(hours: 24));
    });
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    if (ok && state.hasTemporaryThemes) {
      if (then != null) state.setPalette(then);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Temas liberados por 24h! 🎨')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Vídeo não disponível agora. Tente de novo.')));
    }
  }
}

class _PaletteTile extends StatelessWidget {
  const _PaletteTile({
    required this.palette,
    required this.selected,
    required this.locked,
    required this.onTap,
  });

  final AppPalette palette;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: AppTheme.gradient(palette.gradient),
                    borderRadius: BorderRadius.circular(16),
                    border: selected
                        ? Border.all(color: palette.accent, width: 3)
                        : null,
                    boxShadow: [
                      BoxShadow(
                          color: palette.accent.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4)),
                    ],
                  ),
                ),
                if (locked)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.28),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.lock_rounded,
                          color: Colors.white, size: 26),
                    ),
                  ),
                if (selected)
                  const Positioned(
                    top: 6,
                    right: 6,
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.check_rounded,
                          size: 16, color: Colors.black87),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(palette.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600)),
        ],
      ),
    );
  }
}
