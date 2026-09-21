import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import '../../core/models/transaction.dart';
import '../../core/notifiers/transaction_notifier.dart';
import '../../app/theme.dart';
import 'transaction_detail_screen.dart';
import 'transaction_form_screen.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: QeedaScope.of(context),
      builder: (context, _) {
        final notifier = QeedaScope.of(context);
        return Scaffold(
          appBar: AppBar(
            title: const Text('العمليات'),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(100),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'بحث...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        isDense: true,
                      ),
                      onChanged: notifier.setSearch,
                    ),
                  ),
                  _FilterBar(
                    selected: notifier.filterType,
                    onChanged: notifier.setFilter,
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),
          body: notifier.loading
              ? const Center(child: CircularProgressIndicator())
              : notifier.transactions.isEmpty
                  ? _EmptyState(
                      hasFilter:
                          notifier.filterType != null ||
                          notifier.searchQuery.isNotEmpty,
                    )
                  : _TransactionList(transactions: notifier.transactions),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const TransactionFormScreen(),
                ),
              );
            },
            label: const Text('إضافة'),
            icon: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}

class _FilterBar extends StatelessWidget {
  final TransactionType? selected;
  final ValueChanged<TransactionType?> onChanged;

  const _FilterBar({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          _Chip(
            label: 'الكل',
            active: selected == null,
            onTap: () => onChanged(null),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'استلام',
            active: selected == TransactionType.income,
            onTap: () => onChanged(TransactionType.income),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'مصروف',
            active: selected == TransactionType.expense,
            onTap: () => onChanged(TransactionType.expense),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'ديون',
            active: selected != null && selected!.isDebt,
            onTap: () => onChanged(TransactionType.debtReceivable),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _Chip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF1A1A2E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? const Color(0xFF1A1A2E)
                : const Color(0xFFE0E0E0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : const Color(0xFF6B6B6B),
            fontSize: 13,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _TransactionList extends StatelessWidget {
  final List<Transaction> transactions;

  const _TransactionList({required this.transactions});

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<Transaction>>{};
    for (final t in transactions) {
      final key = DateFormat('yyyy-MM-dd').format(t.transactionDate);
      groups.putIfAbsent(key, () => []).add(t);
    }
    final sortedKeys = groups.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      itemCount: sortedKeys.length,
      itemBuilder: (context, i) {
        final key = sortedKeys[i];
        final items = groups[key]!;
        final date = DateTime.parse(key);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                _formatDateHeader(date),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B6B6B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ...items.map((t) => _TransactionTile(transaction: t)),
          ],
        );
      },
    );
  }

  String _formatDateHeader(DateTime d) {
    final now = DateTime.now();
    if (d.year == now.year && d.month == now.month && d.day == now.day) {
      return 'اليوم';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (d.year == yesterday.year &&
        d.month == yesterday.month &&
        d.day == yesterday.day) {
      return 'أمس';
    }
    return DateFormat('d MMMM yyyy', 'ar').format(d);
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaction transaction;

  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final isIncome = t.type == TransactionType.income;
    final isDebt = t.type.isDebt;
    Color amountColor;
    String sign;
    if (isDebt) {
      amountColor = Colors.orange[800]!;
      sign = '';
    } else if (isIncome) {
      amountColor = kIncomeColor;
      sign = '+';
    } else {
      amountColor = kExpenseColor;
      sign = '-';
    }

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TransactionDetailScreen(transaction: t),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFE0E0E0), width: 0.5),
          ),
        ),
        child: Row(
          children: [
            _TypeIcon(type: t.type),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (t.partyName != null)
                    Text(
                      t.partyName!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (t.category != null)
                    Text(
                      t.category!.arabicLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B6B6B),
                      ),
                    ),
                  if (t.partyName == null && t.category == null)
                    Text(
                      t.type.arabicLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B6B6B),
                      ),
                    ),
                ],
              ),
            ),
            Text(
              '$sign${formatAmount(t.amount)} ${t.currency}',
              style: TextStyle(
                color: amountColor,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
              textDirection: TextDirection.ltr,
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeIcon extends StatelessWidget {
  final TransactionType type;
  const _TypeIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;
    switch (type) {
      case TransactionType.income:
        bg = const Color(0xFFE8F5E9);
        fg = kIncomeColor;
        icon = Icons.arrow_downward;
      case TransactionType.expense:
        bg = const Color(0xFFFFEBEE);
        fg = kExpenseColor;
        icon = Icons.arrow_upward;
      case TransactionType.debtReceivable:
        bg = const Color(0xFFFFF3E0);
        fg = Colors.orange[700]!;
        icon = Icons.person_outline;
      case TransactionType.debtPayable:
        bg = const Color(0xFFFFF3E0);
        fg = Colors.orange[900]!;
        icon = Icons.person_outline;
    }
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Icon(icon, color: fg, size: 18),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasFilter;
  const _EmptyState({required this.hasFilter});

  @override
  Widget build(BuildContext context) {
    if (hasFilter) {
      return const Center(
        child: Text(
          'لا توجد عمليات مطابقة',
          style: TextStyle(color: Color(0xFF6B6B6B)),
        ),
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'لا توجد عمليات بعد',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B6B6B),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'أضف أول عملية أو شارك إيصالاً من WhatsApp.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF6B6B6B)),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const TransactionFormScreen(),
                  ),
                );
              },
              child: const Text('إضافة عملية'),
            ),
          ],
        ),
      ),
    );
  }
}
