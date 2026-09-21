import 'package:flutter/material.dart';

const _kPrimary = Color(0xFF1A1A2E);
const _kBackground = Color(0xFFF9F9F7);
const _kSurface = Color(0xFFFFFFFF);
const _kTextPrimary = Color(0xFF0F0F0F);
const _kTextSecondary = Color(0xFF6B6B6B);
const _kDivider = Color(0xFFE0E0E0);
const kIncomeColor = Color(0xFF2E7D32);
const kExpenseColor = Color(0xFFC62828);

ThemeData buildTheme() {
  final base = ThemeData.light(useMaterial3: true);
  return base.copyWith(
    colorScheme: ColorScheme.fromSeed(
      seedColor: _kPrimary,
      brightness: Brightness.light,
      surface: _kSurface,
    ).copyWith(
      surface: _kSurface,
      onSurface: _kTextPrimary,
    ),
    scaffoldBackgroundColor: _kBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: _kSurface,
      foregroundColor: _kTextPrimary,
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: _kTextPrimary,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        fontFamily: 'Segoe UI',
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: _kSurface,
      selectedItemColor: _kPrimary,
      unselectedItemColor: _kTextSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 4,
      selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 11),
    ),
    cardTheme: CardThemeData(
      color: _kSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: _kDivider),
      ),
      margin: EdgeInsets.zero,
    ),
    dividerTheme: const DividerThemeData(color: _kDivider, space: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _kSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _kDivider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _kDivider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _kPrimary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      labelStyle: const TextStyle(color: _kTextSecondary, fontSize: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: _kPrimary),
    ),
    listTileTheme: const ListTileThemeData(
      minLeadingWidth: 0,
      contentPadding: EdgeInsets.symmetric(horizontal: 16),
    ),
    textTheme: base.textTheme.copyWith(
      bodyLarge: const TextStyle(
        color: _kTextPrimary,
        fontSize: 15,
        fontWeight: FontWeight.normal,
      ),
      bodyMedium: const TextStyle(color: _kTextPrimary, fontSize: 14),
      bodySmall: const TextStyle(color: _kTextSecondary, fontSize: 12),
      labelSmall: const TextStyle(color: _kTextSecondary, fontSize: 11),
    ),
  );
}

String formatAmount(int amount) {
  if (amount >= 1000000) {
    final m = amount / 1000000;
    return '${m % 1 == 0 ? m.toInt() : m.toStringAsFixed(1)}م';
  }
  if (amount >= 1000) {
    final k = amount / 1000;
    return '${k % 1 == 0 ? k.toInt() : k.toStringAsFixed(1)}ك';
  }
  return _addCommas(amount);
}

String formatAmountFull(int amount) {
  return _addCommas(amount);
}

String _addCommas(int n) {
  final s = n.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}
