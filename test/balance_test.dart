import 'package:flutter_test/flutter_test.dart';
import 'package:qeeeda/core/models/transaction.dart';

Transaction _make({
  required TransactionType type,
  required int amount,
}) {
  final now = DateTime(2024, 1, 1);
  return Transaction(
    type: type,
    amount: amount,
    transactionDate: now,
    createdAt: now,
  );
}

void main() {
  group('Balance logic', () {
    test('income increases balance effect', () {
      final t = _make(type: TransactionType.income, amount: 100000);
      expect(t.balanceEffect, 100000);
    });

    test('expense decreases balance effect', () {
      final t = _make(type: TransactionType.expense, amount: 25000);
      expect(t.balanceEffect, -25000);
    });

    test('debt receivable has zero balance effect', () {
      final t = _make(type: TransactionType.debtReceivable, amount: 50000);
      expect(t.balanceEffect, 0);
    });

    test('debt payable has zero balance effect', () {
      final t = _make(type: TransactionType.debtPayable, amount: 50000);
      expect(t.balanceEffect, 0);
    });

    test('net balance across multiple transactions', () {
      final transactions = [
        _make(type: TransactionType.income, amount: 100000),
        _make(type: TransactionType.expense, amount: 25000),
        _make(type: TransactionType.income, amount: 50000),
        _make(type: TransactionType.expense, amount: 10000),
        _make(type: TransactionType.debtReceivable, amount: 200000),
      ];
      // 100000 + 50000 - 25000 - 10000 = 115000 (debt excluded)
      final balance = transactions.fold<int>(0, (s, t) => s + t.balanceEffect);
      expect(balance, 115000);
    });

    test('zero balance when no transactions', () {
      final balance = <Transaction>[].fold<int>(0, (s, t) => s + t.balanceEffect);
      expect(balance, 0);
    });
  });

  group('Transaction model', () {
    test('isDebt is true for debt types', () {
      expect(
        _make(type: TransactionType.debtReceivable, amount: 1).type.isDebt,
        true,
      );
      expect(
        _make(type: TransactionType.debtPayable, amount: 1).type.isDebt,
        true,
      );
    });

    test('isDebt is false for income/expense', () {
      expect(
        _make(type: TransactionType.income, amount: 1).type.isDebt,
        false,
      );
      expect(
        _make(type: TransactionType.expense, amount: 1).type.isDebt,
        false,
      );
    });

    test('copyWith preserves fields', () {
      final now = DateTime(2024, 6, 15);
      final t = Transaction(
        id: 1,
        type: TransactionType.income,
        amount: 50000,
        partyName: 'Ahmed',
        transactionDate: now,
        createdAt: now,
      );
      final updated = t.copyWith(amount: 60000, partyName: 'Mohamed');
      expect(updated.id, 1);
      expect(updated.amount, 60000);
      expect(updated.partyName, 'Mohamed');
      expect(updated.type, TransactionType.income);
      expect(updated.transactionDate, now);
    });

    test('fromMap round-trips through toMap', () {
      final now = DateTime(2024, 3, 10, 12, 0, 0);
      final t = Transaction(
        id: 5,
        type: TransactionType.expense,
        amount: 12500,
        currency: 'SDG',
        partyName: 'Test',
        category: TransactionCategory.food,
        paymentMethod: PaymentMethod.bankak,
        note: 'lunch',
        transactionDate: now,
        createdAt: now,
        source: 'manual',
      );
      final map = t.toMap();
      final restored = Transaction.fromMap(map);
      expect(restored.id, t.id);
      expect(restored.type, t.type);
      expect(restored.amount, t.amount);
      expect(restored.partyName, t.partyName);
      expect(restored.category, t.category);
      expect(restored.paymentMethod, t.paymentMethod);
      expect(restored.note, t.note);
    });
  });
}
