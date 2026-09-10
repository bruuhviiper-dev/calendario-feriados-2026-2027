import 'package:flutter/material.dart';

/// Tema do app — teal/petróleo (sereno, reflexivo, profundo).
class AppTheme {
  AppTheme._();

  static const brand = Color(0xFF2563EB); // azul calendario
  static const brandDark = Color(0xFF1D4ED8);
  static const gold = Color(0xFF9FE0DE);

  /// Gradiente da "frase do dia" e da marca.
  static const hero = [Color(0xFF2563EB), Color(0xFF3B82F6)];

  static LinearGradient gradient(List<Color> colors) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      );

  static ThemeData light([Color accent = brand]) {
    return ThemeData(
      useMaterial3: true,
      colorScheme:
          ColorScheme.fromSeed(seedColor: accent, brightness: Brightness.light),
      scaffoldBackgroundColor: const Color(0xFFEFF4F5),
      appBarTheme: const AppBarTheme(centerTitle: false),
    );
  }

  static ThemeData dark([Color accent = brand]) {
    return ThemeData(
      useMaterial3: true,
      colorScheme:
          ColorScheme.fromSeed(seedColor: accent, brightness: Brightness.dark),
      scaffoldBackgroundColor: const Color(0xFF0E1518),
      appBarTheme: const AppBarTheme(centerTitle: false),
    );
  }
}
