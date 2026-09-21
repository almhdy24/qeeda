import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;
import 'package:qeeeda/core/database/database_helper.dart';
import 'package:qeeeda/core/models/transaction.dart';

Transaction _tx({
  int? id,
  TransactionType type = TransactionType.expense,
  int amount = 1000,
  String? party,
  TransactionCategory? category,
}) {
  final now = DateTime(2024, 6, 1);
  return Transaction(
    id: id,
    type: type,
    amount: amount,
    partyName: party,
    category: category,
    transactionDate: now,
    createdAt: now,
  );
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    DatabaseHelper.resetForTest();
  });

  group('DatabaseHelper CRUD', () {
    test('insert and retrieve', () async {
      final db = DatabaseHelper.instance;
      final id = await db.insert(_tx(amount: 5000, party: 'Ali'));
      expect(id, greaterThan(0));

      final found = await db.getById(id);
      expect(found, isNotNull);
      expect(found!.amount, 5000);
      expect(found.partyName, 'Ali');
    });

    test('update changes fields', () async {
      final db = DatabaseHelper.instance;
      final id = await db.insert(_tx(amount: 1000));
      final original = await db.getById(id);
      final updated = original!.copyWith(amount: 2000, partyName: 'Bob');
      await db.update(updated);

      final found = await db.getById(id);
      expect(found!.amount, 2000);
      expect(found.partyName, 'Bob');
    });

    test('delete removes record', () async {
      final db = DatabaseHelper.instance;
      final id = await db.insert(_tx(amount: 500));
      await db.delete(id);
      final found = await db.getById(id);
      expect(found, isNull);
    });

    test('getAll returns all records', () async {
      final db = DatabaseHelper.instance;
      await db.insert(_tx(amount: 100));
      await db.insert(_tx(amount: 200));
      await db.insert(_tx(amount: 300));
      final all = await db.getAll();
      expect(all.length, 3);
    });

    test('getAll filters by type', () async {
      final db = DatabaseHelper.instance;
      await db.insert(_tx(type: TransactionType.income, amount: 1000));
      await db.insert(_tx(type: TransactionType.expense, amount: 500));
      await db.insert(_tx(type: TransactionType.income, amount: 2000));

      final incomes = await db.getAll(type: TransactionType.income);
      expect(incomes.length, 2);
      expect(incomes.every((t) => t.type == TransactionType.income), true);
    });

    test('getAll filters by search query', () async {
      final db = DatabaseHelper.instance;
      await db.insert(_tx(party: 'Ahmed'));
      await db.insert(_tx(party: 'Mohamed'));
      await db.insert(_tx(party: 'Ali'));

      final results = await db.getAll(query: 'Ahmed');
      expect(results.length, 1);
      expect(results.first.partyName, 'Ahmed');
    });

    test('getAll ordered by date descending', () async {
      final db = DatabaseHelper.instance;
      final t1 = Transaction(
        type: TransactionType.expense,
        amount: 100,
        transactionDate: DateTime(2024, 1, 1),
        createdAt: DateTime.now(),
      );
      final t2 = Transaction(
        type: TransactionType.expense,
        amount: 200,
        transactionDate: DateTime(2024, 3, 1),
        createdAt: DateTime.now(),
      );
      final t3 = Transaction(
        type: TransactionType.expense,
        amount: 300,
        transactionDate: DateTime(2024, 2, 1),
        createdAt: DateTime.now(),
      );
      await db.insert(t1);
      await db.insert(t2);
      await db.insert(t3);

      final all = await db.getAll();
      expect(all[0].amount, 200);
      expect(all[1].amount, 300);
      expect(all[2].amount, 100);
    });
  });

  group('Summary', () {
    test('calculates income, expense and balance', () async {
      final db = DatabaseHelper.instance;
      await db.insert(_tx(type: TransactionType.income, amount: 100000));
      await db.insert(_tx(type: TransactionType.expense, amount: 25000));
      await db.insert(_tx(type: TransactionType.expense, amount: 10000));

      final s = await db.getSummary();
      expect(s['income'], 100000);
      expect(s['expense'], 35000);
      expect(s['balance'], 65000);
    });

    test('debt transactions do not affect income/expense summary', () async {
      final db = DatabaseHelper.instance;
      await db.insert(
        _tx(type: TransactionType.debtReceivable, amount: 50000),
      );
      await db.insert(_tx(type: TransactionType.income, amount: 10000));
      final s = await db.getSummary();
      expect(s['income'], 10000);
      expect(s['expense'], 0);
    });
  });
}
