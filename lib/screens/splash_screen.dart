import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/app_info.dart';

/// Abertura da marca (Frases para Refletir) — fundo rosa em gradiente, com animação de
/// escala/fade. Desenhada por cima do app e esmaece (sem "piscar"), ver
/// _RootGate no main. SafeArea garante que a assinatura não encoste na barra de
/// navegação (edge-to-edge).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logoScale = CurvedAnimation(parent: _c, curve: Curves.elasticOut);
    final fade = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.12, 0.45, curve: Curves.easeOut),
    );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ScaleTransition(
                      scale: logoScale,
                      child: Container(
                        width: 160,
                        height: 160,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.3),
                              Colors.white.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                        child: const Text('📅', style: TextStyle(fontSize: 92)),
                      ),
                    ),
                    const SizedBox(height: 22),
                    FadeTransition(
                      opacity: fade,
                      child: Text(
                        'Calendário',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FadeTransition(
                      opacity: fade,
                      child: Text(
                        'feriados e datas · sempre atualizado 📅',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFFCFE3E8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: FadeTransition(
                  opacity: fade,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 22),
                    child: Text(
                      'por ${AppInfo.developer}',
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        color: Colors.white.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
