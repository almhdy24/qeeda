import '../models/transaction.dart';

class ParseResult {
  final int? amount;
  final TransactionType? type;
  final String? partyName;
  final DateTime? date;
  final String originalText;
  final bool isAmountConfident;
  final bool isTypeConfident;

  const ParseResult({
    this.amount,
    this.type,
    this.partyName,
    this.date,
    required this.originalText,
    this.isAmountConfident = false,
    this.isTypeConfident = false,
  });
}

class ParserService {
  static final ParserService instance = ParserService._();
  ParserService._();

  static const _incomeKeywords = [
    'استلم',
    'استلام',
    'وصلني',
    'حول لي',
    'حوّل لي',
    'حولت لي',
    'تم التحويل',
    'تم استلام',
    'received',
    'sent me',
    'transfer to you',
    'credited',
    'incoming',
  ];

  static const _expenseKeywords = [
    'دفعت',
    'دفع',
    'اشتريت',
    'شراء',
    'مصروف',
    'سحب',
    'تحويل من',
    'paid',
    'purchase',
    'payment',
    'deducted',
    'debited',
    'outgoing',
  ];

  ParseResult parse(String text) {
    if (text.trim().isEmpty) {
      return ParseResult(originalText: text);
    }

    final amount = _extractAmount(text);
    final type = _detectType(text);
    final party = _extractParty(text);
    final date = _extractDate(text);

    return ParseResult(
      amount: amount?.value,
      type: type?.type,
      partyName: party,
      date: date,
      originalText: text,
      isAmountConfident: amount?.confident ?? false,
      isTypeConfident: type?.confident ?? false,
    );
  }

  _AmountResult? _extractAmount(String text) {
    // Remove Arabic thousands separator (٬) and Latin comma thousands separator
    // and normalize Arabic-Indic digits to ASCII
    final normalized = _normalizeText(text);

    // Pattern: digits possibly separated by commas or spaces as thousands separator
    // e.g. 150,000 or 150 000 or 150.000 or 150000
    final patterns = [
      // 150,000 or 150.000 (thousands separator)
      RegExp(r'\b(\d{1,3}(?:[,. ]\d{3})+)\b'),
      // Plain number 4+ digits
      RegExp(r'\b(\d{4,})\b'),
      // 1-3 digit number (less confident)
      RegExp(r'\b(\d{1,3})\b'),
    ];

    for (int i = 0; i < patterns.length; i++) {
      final match = patterns[i].firstMatch(normalized);
      if (match != null) {
        final raw = match.group(1)!.replaceAll(RegExp(r'[,. ]'), '');
        final value = int.tryParse(raw);
        if (value != null && value > 0) {
          // Check for "ألف" (thousand) multiplier after digit
          if (_hasThousandMultiplier(text, match.start, match.end)) {
            return _AmountResult(value * 1000, confident: true);
          }
          return _AmountResult(value, confident: i < 2);
        }
      }
    }

    // Try Arabic-Indic digits
    final arabicMatch = RegExp(r'[٠-٩]{2,}').firstMatch(text);
    if (arabicMatch != null) {
      final value = int.tryParse(_arabicIndicToAscii(arabicMatch.group(0)!));
      if (value != null && value > 0) {
        return _AmountResult(value, confident: true);
      }
    }

    return null;
  }

  bool _hasThousandMultiplier(String text, int start, int end) {
    final after = text.substring(end).trim();
    return after.startsWith('ألف') ||
        after.startsWith('الف') ||
        after.toLowerCase().startsWith('k ') ||
        after.toLowerCase().startsWith('k\n');
  }

  _TypeResult? _detectType(String text) {
    final lower = text.toLowerCase();
    int incomeScore = 0;
    int expenseScore = 0;

    for (final kw in _incomeKeywords) {
      if (lower.contains(kw.toLowerCase())) incomeScore++;
    }
    for (final kw in _expenseKeywords) {
      if (lower.contains(kw.toLowerCase())) expenseScore++;
    }

    if (incomeScore > 0 && incomeScore > expenseScore) {
      return _TypeResult(TransactionType.income, confident: incomeScore >= 1);
    }
    if (expenseScore > 0 && expenseScore > incomeScore) {
      return _TypeResult(TransactionType.expense, confident: expenseScore >= 1);
    }
    return null;
  }

  String? _extractParty(String text) {
    // Look for "from <Name>" or "to <Name>" patterns (English)
    final fromMatch = RegExp(
      r'\bfrom\s+([A-Z][a-zA-Z]+(?:\s+[A-Z][a-zA-Z]+)?)',
    ).firstMatch(text);
    if (fromMatch != null) return fromMatch.group(1);

    final toMatch = RegExp(
      r'\bto\s+([A-Z][a-zA-Z]+(?:\s+[A-Z][a-zA-Z]+)?)',
    ).firstMatch(text);
    if (toMatch != null) return toMatch.group(1);

    return null;
  }

  DateTime? _extractDate(String text) {
    // Simple date patterns: dd/mm/yyyy or yyyy-mm-dd
    final dmyMatch = RegExp(
      r'\b(\d{1,2})[/\-](\d{1,2})[/\-](\d{4})\b',
    ).firstMatch(text);
    if (dmyMatch != null) {
      final d = int.tryParse(dmyMatch.group(1)!);
      final m = int.tryParse(dmyMatch.group(2)!);
      final y = int.tryParse(dmyMatch.group(3)!);
      if (d != null && m != null && y != null) {
        if (m >= 1 && m <= 12 && d >= 1 && d <= 31) {
          return DateTime(y, m, d);
        }
      }
    }

    final ymdMatch = RegExp(
      r'\b(\d{4})[/\-](\d{1,2})[/\-](\d{1,2})\b',
    ).firstMatch(text);
    if (ymdMatch != null) {
      final y = int.tryParse(ymdMatch.group(1)!);
      final m = int.tryParse(ymdMatch.group(2)!);
      final d = int.tryParse(ymdMatch.group(3)!);
      if (d != null && m != null && y != null) {
        if (m >= 1 && m <= 12 && d >= 1 && d <= 31) {
          return DateTime(y, m, d);
        }
      }
    }

    return null;
  }

  String _normalizeText(String text) {
    return _arabicIndicToAscii(text)
        .replaceAll('،', ',')
        .replaceAll('٬', ',');
  }

  String _arabicIndicToAscii(String text) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    var result = text;
    for (int i = 0; i < arabicDigits.length; i++) {
      result = result.replaceAll(arabicDigits[i], '$i');
    }
    return result;
  }
}

class _AmountResult {
  final int value;
  final bool confident;
  const _AmountResult(this.value, {required this.confident});
}

class _TypeResult {
  final TransactionType type;
  final bool confident;
  const _TypeResult(this.type, {required this.confident});
}
