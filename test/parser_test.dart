import 'package:flutter_test/flutter_test.dart';
import 'package:qeeeda/core/services/parser_service.dart';
import 'package:qeeeda/core/models/transaction.dart';

void main() {
  final parser = ParserService.instance;

  group('Amount extraction', () {
    test('extracts plain integer', () {
      final r = parser.parse('Received 150000 SDG');
      expect(r.amount, 150000);
      expect(r.isAmountConfident, true);
    });

    test('extracts comma-separated thousands', () {
      final r = parser.parse('حولت لي 150,000 جنيه');
      expect(r.amount, 150000);
    });

    test('extracts Arabic with SDG suffix', () {
      final r = parser.parse('تم تحويل 25,000 SDG');
      expect(r.amount, 25000);
    });

    test('extracts plain expense amount', () {
      final r = parser.parse('دفعت 25,000');
      expect(r.amount, 25000);
    });

    test('extracts 4-digit number', () {
      final r = parser.parse('paid 5000');
      expect(r.amount, 5000);
    });

    test('no amount from empty text', () {
      final r = parser.parse('');
      expect(r.amount, isNull);
    });

    test('Arabic-Indic digits', () {
      final r = parser.parse('المبلغ ١٥٠٠٠٠ جنيه');
      expect(r.amount, 150000);
    });
  });

  group('Type detection', () {
    test('detects income from Arabic received keyword', () {
      final r = parser.parse('وصلني مبلغ 50000');
      expect(r.type, TransactionType.income);
    });

    test('detects income from English received', () {
      final r = parser.parse('Received 150000 SDG from Ahmed');
      expect(r.type, TransactionType.income);
    });

    test('detects expense from Arabic paid keyword', () {
      final r = parser.parse('دفعت 25,000');
      expect(r.type, TransactionType.expense);
    });

    test('detects expense from English paid', () {
      final r = parser.parse('paid 5000 for transport');
      expect(r.type, TransactionType.expense);
    });

    test('returns null type for ambiguous text', () {
      final r = parser.parse('150000 SDG');
      expect(r.type, isNull);
    });
  });

  group('Party extraction', () {
    test('extracts name after from', () {
      final r = parser.parse('Received 150000 SDG from Ahmed');
      expect(r.partyName, 'Ahmed');
    });

    test('no party for Arabic-only text', () {
      final r = parser.parse('دفعت 25000 للمطعم');
      expect(r.partyName, isNull);
    });
  });

  group('Date extraction', () {
    test('extracts dd/mm/yyyy', () {
      final r = parser.parse('تحويل بتاريخ 15/06/2024');
      expect(r.date?.day, 15);
      expect(r.date?.month, 6);
      expect(r.date?.year, 2024);
    });

    test('extracts yyyy-mm-dd', () {
      final r = parser.parse('Transaction on 2024-01-20');
      expect(r.date?.year, 2024);
      expect(r.date?.month, 1);
      expect(r.date?.day, 20);
    });

    test('no date when absent', () {
      final r = parser.parse('دفعت 1000');
      expect(r.date, isNull);
    });
  });
}
