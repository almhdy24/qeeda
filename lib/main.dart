import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/theme.dart';
import 'core/notifiers/transaction_notifier.dart';
import 'core/services/share_service.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/import/import_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/statistics/statistics_screen.dart';
import 'features/transactions/transactions_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ar', null);

  final notifier = TransactionNotifier();
  final shareService = ShareService.instance;
  shareService.initialize();

  // Load existing data before showing UI
  await notifier.load();

  final initialShare = await shareService.getInitialShare();

  runApp(
    QeedaScope(
      notifier: notifier,
      child: QeedaApp(initialShare: initialShare, shareService: shareService),
    ),
  );
}

class QeedaApp extends StatefulWidget {
  final SharedData? initialShare;
  final ShareService shareService;

  const QeedaApp({
    super.key,
    required this.initialShare,
    required this.shareService,
  });

  @override
  State<QeedaApp> createState() => _QeedaAppState();
}

class _QeedaAppState extends State<QeedaApp> {
  final _navKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    widget.shareService.onNewShare = (data) {
      _navKey.currentState?.push(
        MaterialPageRoute(builder: (_) => ImportScreen(shared: data)),
      );
    };
    // If app was opened via share intent, navigate after first frame
    if (widget.initialShare != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => ImportScreen(shared: widget.initialShare!),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'قيدة',
      theme: buildTheme(),
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      navigatorKey: _navKey,
      home: const _MainScaffold(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class _MainScaffold extends StatefulWidget {
  const _MainScaffold();

  @override
  State<_MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<_MainScaffold> {
  int _index = 0;

  static const _screens = [
    DashboardScreen(),
    TransactionsScreen(),
    StatisticsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_outlined),
            activeIcon: Icon(Icons.list_alt),
            label: 'العمليات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'الإحصاءات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'الإعدادات',
          ),
        ],
      ),
    );
  }
}
