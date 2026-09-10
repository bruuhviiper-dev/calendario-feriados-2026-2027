import 'package:flutter/material.dart';

import '../data/app_palettes.dart';

enum ProductKind { removeAds, watermark, pack, theme, bundle, subscription }

enum PurchaseResult { success, pending, cancelled, error, unavailable }

class StoreProduct {
  const StoreProduct({
    required this.id,
    required this.kind,
    required this.title,
    required this.description,
    required this.fallbackPrice,
    this.emoji = '✨',
    this.paletteId,
  });

  final String id;
  final ProductKind kind;
  final String title;
  final String description;
  final String fallbackPrice;
  final String emoji;
  final String? paletteId;
}

/// Catálogo da Loja Premium. Os `id` devem bater com os produtos do Play Console.
class StoreProducts {
  StoreProducts._();

  static const removeAds = StoreProduct(
    id: 'no_ads',
    kind: ProductKind.removeAds,
    title: 'Remover anúncios',
    description: 'Use o app sem interrupções. Pagamento único.',
    fallbackPrice: 'R\$ 8,90',
    emoji: '🚫',
  );

  static const removeWatermark = StoreProduct(
    id: 'remove_watermark',
    kind: ProductKind.watermark,
    title: "Remover marca d'água",
    description: 'Compartilhe suas imagens sem a assinatura do app.',
    fallbackPrice: 'R\$ 6,90',
    emoji: '💧',
  );

  static const packExclusivas = StoreProduct(
    id: 'pack_oracoes',
    kind: ProductKind.pack,
    title: 'Pacote Exclusivo',
    description: 'Frases Para Refletir, Inspiração e Bonitas Curtas.',
    fallbackPrice: 'R\$ 9,90',
    emoji: '🌟',
  );

  static const premiumBundle = StoreProduct(
    id: 'premium_bundle',
    kind: ProductKind.bundle,
    title: 'Premium (tudo)',
    description: 'Sem anúncios + todos os temas + conteúdo exclusivo.',
    fallbackPrice: 'R\$ 24,90',
    emoji: '👑',
  );

  static const premiumMonthly = StoreProduct(
    id: 'premium_monthly',
    kind: ProductKind.subscription,
    title: 'Premium mensal',
    description: 'Tudo liberado enquanto a assinatura estiver ativa.',
    fallbackPrice: 'R\$ 5,90/mês',
    emoji: '👑',
  );

  static const premiumYearly = StoreProduct(
    id: 'premium_yearly',
    kind: ProductKind.subscription,
    title: 'Premium anual',
    description: 'Todos os recursos o ano inteiro, com desconto.',
    fallbackPrice: 'R\$ 49,90/ano',
    emoji: '👑',
  );

  /// Nenhuma categoria bloqueada — todo o conteúdo é grátis.
  static const Set<String> exclusiveCategoryIds = {};

  static const Set<String> subscriptionIds = {
    'premium_monthly',
    'premium_yearly',
  };

  static List<StoreProduct> get themes => [
        for (final p in AppPalettes.all)
          if (p.premium)
            StoreProduct(
              id: p.productId!,
              kind: ProductKind.theme,
              title: 'Tema ${p.name}',
              description: 'Deixe o app com a sua cara.',
              fallbackPrice: 'R\$ 4,90',
              emoji: '🎨',
              paletteId: p.id,
            ),
      ];

  /// Único produto à venda: remover anúncios (compra única). Todo o resto grátis.
  static List<StoreProduct> get all => [removeAds];

  static StoreProduct? byId(String id) {
    for (final p in all) {
      if (p.id == id) return p;
    }
    return null;
  }

  static Color emojiTint(ProductKind kind) => switch (kind) {
        ProductKind.removeAds => const Color(0xFFEF4444),
        ProductKind.watermark => const Color(0xFF0EA5E9),
        ProductKind.pack => const Color(0xFF9333EA),
        ProductKind.subscription => const Color(0xFFD9A406),
        ProductKind.bundle => const Color(0xFFD9A406),
        ProductKind.theme => const Color(0xFF7C3AED),
      };
}
