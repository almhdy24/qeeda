import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart' hide Transaction;

import '../models/transaction.dart';

class DatabaseHelper {
  static DatabaseHelper? _instance;
  static Database? _db;
  // Set to ':memory:' in resetForTest() for isolated in-memory test databases.
  static String? _testDbPath;

  DatabaseHelper._();

  static DatabaseHelper get instance {
    _instance ??= DatabaseHelper._();
    return _instance!;
  }

  static void resetForTest({String path = ':memory:'}) {
    _testDbPath = path;
    _db?.close();
    _db = null;
    _instance = null;
  }

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    String path;
    if (_testDbPath != null) {
      path = _testDbPath!;
    } else {
      final dir = await getDatabasesPath();
      path = p.join(dir, 'qeeda.db');
    }
    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        amount INTEGER NOT NULL,
        currency TEXT NOT NULL DEFAULT 'SDG',
        party_name TEXT,
        category TEXT,
        payment_method TEXT NOT NULL DEFAULT 'unknown',
        note TEXT,
        reference TEXT,
        transaction_date INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        source TEXT NOT NULL DEFAULT 'manual',
        source_text TEXT
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_txn_date ON transactions (transaction_date DESC)',
    );
    await db.execute(
      'CREATE INDEX idx_txn_party ON transactions (party_name)',
    );
    await db.execute(
      'CREATE INDEX idx_txn_type ON transactions (type)',
    );
  }

  Future<int> insert(Transaction t) async {
    final db = await database;
    return db.insert('transactions', t.toMap());
  }

  Future<int> update(Transaction t) async {
    final db = await database;
    return db.update(
      'transactions',
      t.toMap(),
      where: 'id = ?',
      whereArgs: [t.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await database;
    return db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<Transaction?> getById(int id) async {
    final db = await database;
    final rows = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Transaction.fromMap(rows.first);
  }

  Future<List<Transaction>> getAll({
    TransactionType? type,
    String? query,
    DateTime? from,
    DateTime? to,
    int? limit,
  }) async {
    final db = await database;
    final conditions = <String>[];
    final args = <Object?>[];

    if (type != null) {
      conditions.add('type = ?');
      args.add(type.name);
    }
    if (from != null) {
      conditions.add('transaction_date >= ?');
      args.add(from.millisecondsSinceEpoch);
    }
    if (to != null) {
      conditions.add('transaction_date <= ?');
      args.add(to.millisecondsSinceEpoch);
    }
    if (query != null && query.isNotEmpty) {
      conditions.add(
        '(party_name LIKE ? OR note LIKE ? OR reference LIKE ?'
        ' OR source_text LIKE ? OR category LIKE ?)',
      );
      final q = '%$query%';
      args.addAll([q, q, q, q, q]);
    }

    final where = conditions.isEmpty ? null : conditions.join(' AND ');

    final rows = await db.query(
      'transactions',
      where: where,
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'transaction_date DESC, id DESC',
      limit: limit,
    );
    return rows.map((m) => Transaction.fromMap(m)).toList();
  }

  Future<List<Transaction>> getRecent(int count) => getAll(limit: count);

  Future<Map<String, int>> getSummary({DateTime? from, DateTime? to}) async {
    final txns = await getAll(from: from, to: to);
    var income = 0;
    var expense = 0;
    for (final t in txns) {
      if (t.type == TransactionType.income) income += t.amount;
      if (t.type == TransactionType.expense) expense += t.amount;
    }
    return {'income': income, 'expense': expense, 'balance': income - expense};
  }
}
