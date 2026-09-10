import 'package:flutter/material.dart';

/// Paleta de cores vendável (tema do app). A "clássica" é grátis.
class AppPalette {
  const AppPalette({
    required this.id,
    required this.name,
    required this.accent,
    required this.gradient,
    this.premium = false,
    this.productId,
  });

  final String id;
  final String name;
  final Color accent;
  final List<Color> gradient;
  final bool premium;
  final String? productId;
}

class AppPalettes {
  AppPalettes._();

  static const classico = AppPalette(
    id: 'classico',
    name: 'Azul',
    accent: Color(0xFF2563EB),
    gradient: [Color(0xFF2563EB), Color(0xFF3B82F6)],
    premium: false,
  );

  static const all = <AppPalette>[
    classico,
    AppPalette(
        id: 'oceano',
        name: 'Oceano',
        accent: Color(0xFF0EA5E9),
        gradient: [Color(0xFF2193B0), Color(0xFF6DD5ED)],
        premium: true,
        productId: 'theme_oceano'),
    AppPalette(
        id: 'purpura',
        name: 'Púrpura',
        accent: Color(0xFF7C3AED),
        gradient: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
        premium: true,
        productId: 'theme_purpura'),
    AppPalette(
        id: 'aurora',
        name: 'Aurora',
        accent: Color(0xFFEC4899),
        gradient: [Color(0xFFF857A6), Color(0xFFFF5858)],
        premium: true,
        productId: 'theme_aurora'),
    AppPalette(
        id: 'floresta',
        name: 'Floresta',
        accent: Color(0xFF2E7D32),
        gradient: [Color(0xFF134E5E), Color(0xFF71B280)],
        premium: true,
        productId: 'theme_floresta'),
    AppPalette(
        id: 'noturno',
        name: 'Noturno',
        accent: Color(0xFF6366F1),
        gradient: [Color(0xFF141E30), Color(0xFF243B55)],
        premium: true,
        productId: 'theme_noturno'),
  ];

  /// Paletas premium (desbloqueadas por vídeo ou compra).
  static List<AppPalette> get premiumOnes =>
      all.where((p) => p.premium).toList();

  static AppPalette byId(String id) =>
      all.firstWhere((p) => p.id == id, orElse: () => classico);
}
