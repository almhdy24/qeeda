import 'package:flutter/widgets.dart';
import '../database/database_helper.dart';
import '../models/transaction.dart';

class TransactionNotifier extends ChangeNotifier {
  final _db = DatabaseHelper.instance;

  List<Transaction> _transactions = [];
  List<Transaction> _filtered = [];
  bool _loading = false;
  String _searchQuery = '';
  TransactionType? _filterType;

  List<Transaction> get transactions => _filtered;
  bool get loading => _loading;
  String get searchQuery => _searchQuery;
  TransactionType? get filterType => _filterType;

  int _totalIncome = 0;
  int _totalExpense = 0;
  int get totalIncome => _totalIncome;
  int get totalExpense => _totalExpense;
  // Cash balance: income minus expense only. Debt records are excluded.
  int get balance => _totalIncome - _totalExpense;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    try {
      _transactions = await _db.getAll();
      _computeSummary();
      _applyFilter();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> add(Transaction t) async {
    final id = await _db.insert(t);
    final saved = t.copyWith(id: id);
    _transactions.insert(0, saved);
    _computeSummary();
    _applyFilter();
    notifyListeners();
  }

  Future<void> edit(Transaction t) async {
    await _db.update(t);
    final idx = _transactions.indexWhere((x) => x.id == t.id);
    if (idx >= 0) _transactions[idx] = t;
    _computeSummary();
    _applyFilter();
    notifyListeners();
  }

  Future<void> remove(int id) async {
    await _db.delete(id);
    _transactions.removeWhere((t) => t.id == id);
    _computeSummary();
    _applyFilter();
    notifyListeners();
  }

  void setSearch(String query) {
    _searchQuery = query;
    _applyFilter();
    notifyListeners();
  }

  void setFilter(TransactionType? type) {
    _filterType = type;
    _applyFilter();
    notifyListeners();
  }

  List<Transaction> get recentTransactions => _transactions.take(5).toList();

  int get thisMonthIncome {
    final from = _startOfMonth(DateTime.now());
    return _transactions
        .where(
          (t) =>
              t.type == TransactionType.income &&
              !t.transactionDate.isBefore(from),
        )
        .fold(0, (s, t) => s + t.amount);
  }

  int get thisMonthExpense {
    final from = _startOfMonth(DateTime.now());
    return _transactions
        .where(
          (t) =>
              t.type == TransactionType.expense &&
              !t.transactionDate.isBefore(from),
        )
        .fold(0, (s, t) => s + t.amount);
  }

  Map<TransactionCategory, int> get categoryExpensesThisMonth {
    final from = _startOfMonth(DateTime.now());
    final map = <TransactionCategory, int>{};
    for (final t in _transactions) {
      if (t.type == TransactionType.expense &&
          t.category != null &&
          !t.transactionDate.isBefore(from)) {
        map[t.category!] = (map[t.category!] ?? 0) + t.amount;
      }
    }
    return map;
  }

  void _computeSummary() {
    _totalIncome = 0;
    _totalExpense = 0;
    for (final t in _transactions) {
      if (t.type == TransactionType.income) _totalIncome += t.amount;
      if (t.type == TransactionType.expense) _totalExpense += t.amount;
    }
  }

  void _applyFilter() {
    var result = _transactions;

    if (_filterType != null) {
      if (_filterType!.isDebt) {
        result = result.where((t) => t.type.isDebt).toList();
      } else {
        result = result.where((t) => t.type == _filterType).toList();
      }
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((t) {
        return (t.partyName?.toLowerCase().contains(q) ?? false) ||
            (t.note?.toLowerCase().contains(q) ?? false) ||
            (t.reference?.toLowerCase().contains(q) ?? false) ||
            (t.category?.arabicLabel.contains(q) ?? false) ||
            (t.sourceText?.toLowerCase().contains(q) ?? false) ||
            t.amount.toString().contains(q);
      }).toList();
    }

    _filtered = result;
  }

  DateTime _startOfMonth(DateTime d) => DateTime(d.year, d.month, 1);
}

class QeedaScope extends InheritedNotifier<TransactionNotifier> {
  const QeedaScope({
    super.key,
    required TransactionNotifier notifier,
    required super.child,
  }) : super(notifier: notifier);

  static TransactionNotifier of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<QeedaScope>();
    assert(scope?.notifier != null, 'QeedaScope not found in widget tree');
    return scope!.notifier!;
  }
}
