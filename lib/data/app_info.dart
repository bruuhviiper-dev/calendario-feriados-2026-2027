/// Identidade do app + catálogo de apps (cross-promoção / tráfego orgânico).
class AppInfo {
  AppInfo._();

  static const developer = 'Phantom Tecnologia';
  static const appName = 'Calendário 2026 2027 Feriados';
  static const packageId = 'com.calendarioferiados.calendario';

  static String playUrlFor(String id) =>
      'https://play.google.com/store/apps/details?id=$id';

  static const playUrl = 'https://play.google.com/store/apps/details?id=$packageId';
  static const devUrl =
      'https://play.google.com/store/apps/developer?id=Phantom+Tecnologia';
  static const shareFooter = '📲 Baixe grátis: $playUrl';

  static const List<(String, String)> apps = [
    ('Frases e Status Prontos', 'com.frasesstatus.frases_status'),
    ('Frases Bíblicas e Versículos', 'com.frasesbiblicas.frases_biblicas'),
    ('Mensagens de Bom Dia', 'com.mensagens.mensagens'),
    ('Frases de Motivação', 'com.frasesmotivacao.frasesmotivacao'),
    ('Frases Indiretas', 'com.indiretas.indiretas'),
    ('Mensagens de Feliz Aniversário', 'com.aniversario.aniversario'),
    ('Frases de Amor e Romance', 'com.frasesdeamor.amor'),
    ('Frases de Rap e Trap', 'com.frasesderap.rap'),
    ('Frases Engraçadas e Piadas', 'com.frasesengracadas.humor'),
    ('Frases Tristes e Desabafos', 'com.frasestristes.tristes'),
    ('Orações Poderosas e Salmos', 'com.oracoesesalmos.oracoes'),
    ('Frases da Vida', 'com.frasesdavida.vida'),
    ('Frases Bonitas', 'com.frasesbonitas.bonitas'),
  ];

  static List<(String, String)> get otherApps =>
      apps.where((a) => a.$2 != packageId).toList();

  /// Apps em DESTAQUE na aba Mais (lojinha) — incentivo de download.
  /// (emoji, nome, packageId)
  static const List<(String, String, String)> featured = [
    ('🤝', 'Frases de Amizade', 'com.frasesdeamizade.amizade'),
    ('💭', 'Frases para Refletir', 'com.frasespararefletir.refletir'),
    ('🎂', 'Mensagens de Aniversário', 'com.aniversario.aniversario'),
    ('😏', 'Frases Indiretas', 'com.indiretas.indiretas'),
    ('💬', 'Frases para Status', 'com.frasesstatus.frases_status'),
  ];
}