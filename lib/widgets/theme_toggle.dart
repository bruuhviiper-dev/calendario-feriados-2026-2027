import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';

/// Botão de alternar tema (claro/escuro) para a AppBar superior.
/// Fica em todas as telas principais, atalho rápido sem ir em "Mais".
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = context.watch<AppState>().isDark;
    return IconButton(
      tooltip: dark ? 'Modo claro' : 'Modo escuro',
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, anim) =>
            ScaleTransition(scale: anim, child: child),
        child: Icon(
          dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          key: ValueKey(dark),
        ),
      ),
      onPressed: () => context.read<AppState>().toggleTheme(),
    );
  }
}
