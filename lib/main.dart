import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/app_theme.dart';
import 'screens/calendar_screen.dart';
import 'screens/feriados_screen.dart';
import 'screens/more_screen.dart';
import 'screens/splash_screen.dart';
import 'services/ads_service.dart';
import 'services/app_state.dart';
import 'services/notif_service.dart';
import 'services/purchase_service.dart';

/// Navegador raiz do app.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  final prefs = await SharedPreferences.getInstance();
  final appState = AppState(prefs);

  AdsService.instance.init();

  PurchaseService.instance
    ..onEntitlement(appState.grantEntitlement)
    ..onSubscriptionGranted(appState.addSubscription)
    ..init();

  // Avisos de feriado (véspera). Reagenda a cada abertura.
  if (appState.reminderOn) {
    NotifService.instance
        .init()
        .then((_) => NotifService.instance.scheduleHolidayReminders());
  }

  runApp(CalendarioApp(appState: appState));
}

class CalendarioApp extends StatelessWidget {
  const CalendarioApp({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: appState,
      child: Consumer<AppState>(
        builder: (context, state, _) => MaterialApp(
          navigatorKey: rootNavigatorKey,
          title: 'Calendário 2026 2027 Feriados',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(state.accentColor),
          darkTheme: AppTheme.dark(state.accentColor),
          themeMode: state.themeMode,
          home: const _RootGate(),
        ),
      ),
    );
  }
}

/// Splash da marca por ~1.6s, depois esmaece por cima do app.
class _RootGate extends StatefulWidget {
  const _RootGate();

  @override
  State<_RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<_RootGate> {
  bool _ready = false;
  bool _splashGone = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const HomeShell(),
        if (!_splashGone)
          AnimatedOpacity(
            opacity: _ready ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
            onEnd: () {
              if (_ready && mounted) setState(() => _splashGone = true);
            },
            child: const SplashScreen(),
          ),
      ],
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  final _navKeys = List.generate(3, (_) => GlobalKey<NavigatorState>());

  static const _roots = [
    CalendarScreen(),
    FeriadosScreen(),
    MoreScreen(),
  ];

  Widget _tabNavigator(int i) => Navigator(
        key: _navKeys[i],
        onGenerateRoute: (settings) =>
            MaterialPageRoute(builder: (_) => _roots[i], settings: settings),
      );

  @override
  Widget build(BuildContext context) {
    final accent = context.watch<AppState>().accentColor;
    final surface = Theme.of(context).colorScheme.surface;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final nav = _navKeys[_index].currentState;
        if (nav != null && nav.canPop()) {
          nav.pop();
        } else if (_index != 0) {
          setState(() => _index = 0);
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: [for (var i = 0; i < _roots.length; i++) _tabNavigator(i)],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                  color: accent.withValues(alpha: 0.20),
                  blurRadius: 22,
                  offset: const Offset(0, -3)),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: NavigationBarTheme(
              data: NavigationBarThemeData(
                backgroundColor: surface,
                elevation: 0,
                indicatorColor: accent.withValues(alpha: 0.18),
                labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
                    fontSize: 11.5,
                    fontWeight: s.contains(WidgetState.selected)
                        ? FontWeight.w800
                        : FontWeight.w500,
                    color: s.contains(WidgetState.selected) ? accent : null)),
                iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
                    color: s.contains(WidgetState.selected) ? accent : null)),
              ),
              child: NavigationBar(
                selectedIndex: _index,
                height: 66,
                onDestinationSelected: (i) {
                  if (i == _index) {
                    _navKeys[i].currentState?.popUntil((r) => r.isFirst);
                  } else {
                    setState(() => _index = i);
                  }
                  if (!context.read<AppState>().adsRemoved) {
                    AdsService.instance.registerActionAndMaybeShow();
                  }
                },
                destinations: const [
                  NavigationDestination(
                      icon: Icon(Icons.calendar_month_outlined),
                      selectedIcon: Icon(Icons.calendar_month_rounded),
                      label: 'Calendário'),
                  NavigationDestination(
                      icon: Icon(Icons.event_outlined),
                      selectedIcon: Icon(Icons.event_rounded),
                      label: 'Feriados'),
                  NavigationDestination(
                      icon: Icon(Icons.more_horiz_rounded),
                      selectedIcon: Icon(Icons.more_horiz_rounded),
                      label: 'Mais'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
