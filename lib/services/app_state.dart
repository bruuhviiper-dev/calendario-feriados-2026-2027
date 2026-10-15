import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/app_palettes.dart';
import '../data/calendar_event.dart';
import '../data/models.dart';

/// Estado global: favoritos, tema, compras/premium e tema de cores.
/// Tudo salvo localmente (privado do aparelho).
class AppState extends ChangeNotifier {
  AppState(this._prefs) {
    _load();
  }

  final SharedPreferences _prefs;

  static const _kFavorites = 'favorites';
  static const _kThemeMode = 'theme_mode';
  static const _kEntitlements = 'entitlements';
  static const _kSubscriptions = 'subscriptions';
  static const _kPalette = 'palette_id';
  static const _kTempThemes = 'temp_themes_until';
  static const _kReminderOn = 'reminder_on';
  static const _kReminderHour = 'reminder_hour';
  static const _kReminderMin = 'reminder_min';
  static const _kSignature = 'custom_signature';
  static const _kTempPro = 'temp_pro_until';
  static const _kRecipient = 'recipient_name';
  static const _kCatSingle = 'cat_single_col';
  static const _kEvents = 'cal_events_json';

  /// Separador interno para serializar favoritos ("referenciatexto").
  static const _favSep = '';

  static const String pRemoveAds = 'no_ads';
  static const String pWatermark = 'remove_watermark';
  static const String pBundle = 'premium_bundle';
  static const String pPack = 'pack_oracoes';

  // Favoritos guardam o texto completo (não só o id), assim aparecem no
  // Favoritos venham de onde vierem (categorias, "Ver mais", editor...).
  final Map<String, Verse> _favVerses = {};
  final Set<String> _entitlements = {};
  final Set<String> _subscriptions = {};
  ThemeMode _themeMode = ThemeMode.light;
  String _paletteId = 'classico';
  DateTime? _tempThemesUntil;
  String _recipientName = '';
  bool _reminderOn = false;
  int _reminderHour = 8;
  int _reminderMin = 0;
  String _customSignature = '';
  DateTime? _tempProUntil;
  bool _catSingleCol = false;

  /// Eventos pessoais, agrupados por dia (yyyy-MM-dd).
  final Map<String, List<CalendarEvent>> _events = {};

  // ----- básico -----
  /// Frases favoritadas (as mais recentes primeiro).
  List<Verse> get favoriteVerses => _favVerses.values.toList().reversed.toList();
  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;
  bool get hasFavorites => _favVerses.isNotEmpty;
  bool isFavorite(String id) => _favVerses.containsKey(id);

  /// Grade de categorias: true = 1 coluna (card full-width), false = 2 colunas.
  bool get categorySingleColumn => _catSingleCol;
  void toggleCategoryColumns() {
    _catSingleCol = !_catSingleCol;
    _prefs.setBool(_kCatSingle, _catSingleCol);
    notifyListeners();
  }

  // ----- lembrete diário -----
  bool get reminderOn => _reminderOn;
  int get reminderHour => _reminderHour;
  int get reminderMin => _reminderMin;

  // ----- assinatura personalizada (premium) -----
  /// PRO temporário (liberado por anúncio premiado).
  bool get hasTemporaryPro =>
      _tempProUntil != null && _tempProUntil!.isAfter(DateTime.now());
  void grantTemporaryPro(Duration d) {
    _tempProUntil = DateTime.now().add(d);
    _prefs.setInt(_kTempPro, _tempProUntil!.millisecondsSinceEpoch);
    notifyListeners();
  }

  /// Nome do aniversariante (personalização das mensagens).
  String get recipientName => _recipientName;
  void setRecipientName(String v) {
    _recipientName = v.trim();
    _prefs.setString(_kRecipient, _recipientName);
    notifyListeners();
  }

  /// Com nome: substitui {nome}. Sem nome: remove o placeholder de forma
  /// natural, deixando a mensagem completa (genérica).
  String personalize(String text) {
    if (_recipientName.isNotEmpty) {
      return text.replaceAll('{nome}', _recipientName);
    }
    var t = text
        .replaceAll(', {nome}', '')
        .replaceAll('{nome}, ', '')
        .replaceAll(' {nome}', '')
        .replaceAll('{nome}', '')
        .replaceAll('  ', ' ')
        .trim();
    if (t.isNotEmpty) t = t[0].toUpperCase() + t.substring(1);
    return t;
  }

  String get customSignature => _customSignature;

  void setCustomSignature(String value) {
    _customSignature = value.trim();
    _prefs.setString(_kSignature, _customSignature);
    notifyListeners();
  }

  void setReminder({required bool on, int? hour, int? minute}) {
    _reminderOn = on;
    if (hour != null) _reminderHour = hour;
    if (minute != null) _reminderMin = minute;
    _prefs.setBool(_kReminderOn, _reminderOn);
    _prefs.setInt(_kReminderHour, _reminderHour);
    _prefs.setInt(_kReminderMin, _reminderMin);
    notifyListeners();
  }

  // ----- premium / compras -----
  bool get isSubscriber => _subscriptions.isNotEmpty;
  bool get hasBundle =>
      _entitlements.contains(pBundle) || isSubscriber;
  bool get isPremium => hasBundle;

  bool ownsProduct(String id) =>
      _entitlements.contains(id) || hasBundle;

  /// Pode ver o app sem anúncios.
  bool get adsRemoved =>
      _entitlements.contains(pRemoveAds) || hasBundle;

  /// Sem marca d'água: grátis pra todos (editor 100% livre).
  bool get canRemoveWatermark => true;

  /// Todas as categorias são grátis (sem bloqueio/cadeado).
  bool get ownsExclusivePack => true;

  bool isCategoryLocked(bool premium) => false;

  // ----- temas -----
  AppPalette get palette => AppPalettes.byId(_paletteId);
  Color get accentColor => palette.accent;

  bool get hasTemporaryThemes =>
      _tempThemesUntil != null && _tempThemesUntil!.isAfter(DateTime.now());

  /// Quanto falta do desbloqueio temporário (por vídeo). Null se não ativo.
  Duration? get temporaryThemesLeft {
    if (!hasTemporaryThemes) return null;
    return _tempThemesUntil!.difference(DateTime.now());
  }

  /// Acesso aos temas premium: quem removeu anúncios/é premium tem pra sempre;
  /// quem assistiu o vídeo tem por 24h.
  bool get hasThemeAccess => adsRemoved || isPremium || hasTemporaryThemes;

  /// Paleta "clássica" sempre liberada; as premium exigem acesso.
  bool ownsPalette(String paletteId) {
    final p = AppPalettes.byId(paletteId);
    if (!p.premium) return true;
    return hasThemeAccess;
  }

  void _load() {
    for (final e in _prefs.getStringList(_kFavorites) ?? const []) {
      // Formato novo: "referenciatexto". (Ids antigos, sem separador,
      // são descartados — o texto não podia ser reconstruído.)
      final i = e.indexOf('');
      if (i < 0) continue;
      final v = Verse(e.substring(i + 1), e.substring(0, i));
      _favVerses[v.id] = v;
    }
    final t = _prefs.getInt(_kThemeMode);
    if (t != null && t >= 0 && t < ThemeMode.values.length) {
      _themeMode = ThemeMode.values[t];
    }
    _entitlements.addAll(_prefs.getStringList(_kEntitlements) ?? const []);
    _subscriptions.addAll(_prefs.getStringList(_kSubscriptions) ?? const []);
    _paletteId = _prefs.getString(_kPalette) ?? 'classico';
    if (!ownsPalette(_paletteId)) _paletteId = 'classico';
    final ttu = _prefs.getInt(_kTempThemes);
    _tempThemesUntil =
        ttu != null ? DateTime.fromMillisecondsSinceEpoch(ttu) : null;
    _reminderOn = _prefs.getBool(_kReminderOn) ?? true;
    _reminderHour = _prefs.getInt(_kReminderHour) ?? 8;
    _reminderMin = _prefs.getInt(_kReminderMin) ?? 0;
    _customSignature = _prefs.getString(_kSignature) ?? '';
    final tp = _prefs.getInt(_kTempPro);
    _tempProUntil = tp != null ? DateTime.fromMillisecondsSinceEpoch(tp) : null;
    _recipientName = _prefs.getString(_kRecipient) ?? '';
    _catSingleCol = _prefs.getBool(_kCatSingle) ?? false;
    _loadEvents();
  }

  // ----- eventos pessoais -----
  void _loadEvents() {
    _events.clear();
    final raw = _prefs.getString(_kEvents);
    if (raw == null || raw.isEmpty) return;
    try {
      for (final item in jsonDecode(raw) as List) {
        final e = CalendarEvent.fromJson(item as Map<String, dynamic>);
        (_events[e.dayKey] ??= []).add(e);
      }
    } catch (_) {}
  }

  void _saveEvents() {
    final all = [for (final list in _events.values) ...list];
    _prefs.setString(_kEvents, jsonEncode(all.map((e) => e.toJson()).toList()));
  }

  /// Eventos de um dia (ordenados por hora).
  List<CalendarEvent> eventsOn(DateTime day) {
    final list = _events[CalendarEvent.keyOf(day)] ?? const [];
    final sorted = [...list]
      ..sort((a, b) => (a.hour ?? 99) * 60 + (a.minute ?? 0) -
          ((b.hour ?? 99) * 60 + (b.minute ?? 0)));
    return sorted;
  }

  bool hasEventsOn(DateTime day) =>
      (_events[CalendarEvent.keyOf(day)]?.isNotEmpty) ?? false;

  /// Próximos eventos a partir de hoje (agenda).
  List<CalendarEvent> upcomingEvents({int limit = 50}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final all = [for (final list in _events.values) ...list]
        .where((e) => !e.date.isBefore(today))
        .toList()
      ..sort((a, b) => a.when.compareTo(b.when));
    return all.take(limit).toList();
  }

  void addEvent(CalendarEvent e) {
    (_events[e.dayKey] ??= []).add(e);
    _saveEvents();
    notifyListeners();
  }

  void removeEvent(CalendarEvent e) {
    _events[e.dayKey]?.removeWhere((x) => x.id == e.id);
    if (_events[e.dayKey]?.isEmpty ?? false) _events.remove(e.dayKey);
    _saveEvents();
    notifyListeners();
  }

  void toggleFavorite(Verse v) {
    if (_favVerses.remove(v.id) == null) _favVerses[v.id] = v;
    _prefs.setStringList(_kFavorites, [
      for (final f in _favVerses.values) '${f.reference}$_favSep${f.text}',
    ]);
    notifyListeners();
  }

  void toggleTheme() {
    _themeMode = isDark ? ThemeMode.light : ThemeMode.dark;
    _prefs.setInt(_kThemeMode, _themeMode.index);
    notifyListeners();
  }

  void grantEntitlement(String productId) {
    if (_entitlements.add(productId)) {
      _prefs.setStringList(_kEntitlements, _entitlements.toList());
      notifyListeners();
    }
  }

  void addSubscription(String productId) {
    if (_subscriptions.add(productId)) {
      _prefs.setStringList(_kSubscriptions, _subscriptions.toList());
      notifyListeners();
    }
  }

  void setPalette(String paletteId) {
    if (!ownsPalette(paletteId)) return;
    _paletteId = paletteId;
    _prefs.setString(_kPalette, paletteId);
    notifyListeners();
  }

  /// Libera todos os temas por um período (recompensa de anúncio — fase 2).
  void grantTemporaryThemes(Duration duration) {
    _tempThemesUntil = DateTime.now().add(duration);
    _prefs.setInt(_kTempThemes, _tempThemesUntil!.millisecondsSinceEpoch);
    notifyListeners();
  }
}
