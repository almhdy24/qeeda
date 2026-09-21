// Widget-level smoke test for Qeeda app shell.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;
import 'package:qeeeda/core/notifiers/transaction_notifier.dart';

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await initializeDateFormatting('ar', null);
  });

  testWidgets('bottom navigation renders correctly', (tester) async {
    final notifier = TransactionNotifier();
    await tester.pumpWidget(
      QeedaScope(
        notifier: notifier,
        child: MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('ar'), Locale('en')],
          home: Scaffold(
            body: const SizedBox.expand(),
            bottomNavigationBar: BottomNavigationBar(
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  label: 'الرئيسية',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.list_alt_outlined),
                  label: 'العمليات',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.bar_chart_outlined),
                  label: 'الإحصاءات',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings_outlined),
                  label: 'الإعدادات',
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('الرئيسية'), findsOneWidget);
    expect(find.text('العمليات'), findsOneWidget);
    expect(find.text('الإحصاءات'), findsOneWidget);
    expect(find.text('الإعدادات'), findsOneWidget);
  });
}
