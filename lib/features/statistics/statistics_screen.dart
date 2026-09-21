import 'package:flutter/material.dart';
import '../../core/models/transaction.dart';
import '../../core/notifiers/transaction_notifier.dart';
import '../../app/theme.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: QeedaScope.of(context),
      builder: (context, _) {
        final n = QeedaScope.of(context);
        final monthIncome = n.thisMonthIncome;
        final monthExpense = n.thisMonthExpense;
        final monthNet = monthIncome - monthExpense;
        final categories = n.categoryExpensesThisMonth;

        return Scaffold(
          appBar: AppBar(title: const Text('الإحصاءات')),
          body: n.loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _SectionHeader(label: 'هذا الشهر'),
                    const SizedBox(height: 8),
                    _MonthCard(
                      income: monthIncome,
                      expense: monthExpense,
                      net: monthNet,
                    ),
                    if (categories.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _SectionHeader(label: 'المصروفات حسب التصنيف'),
                      const SizedBox(height: 8),
                      _CategoryBreakdown(
                        categories: categories,
                        total: monthExpense,
                      ),
                    ] else if (n.transactions.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: Center(
                          child: Text(
                            'لا توجد بيانات كافية لعرض الإحصاءات',
                            style: TextStyle(color: Color(0xFF6B6B6B)),
                          ),
                        ),
                      ),
                  ],
                ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
    );
  }
}

class _MonthCard extends StatelessWidget {
  final int income;
  final int expense;
  final int net;

  const _MonthCard({
    required this.income,
    required this.expense,
    required this.net,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        children: [
          _StatRow(
            label: 'الدخل',
            amount: income,
            color: kIncomeColor,
            prefix: '+',
          ),
          const Divider(height: 20),
          _StatRow(
            label: 'المصروف',
            amount: expense,
            color: kExpenseColor,
            prefix: '-',
          ),
          const Divider(height: 20),
          _StatRow(
            label: 'الصافي',
            amount: net.abs(),
            color: net >= 0 ? kIncomeColor : kExpenseColor,
            prefix: net >= 0 ? '+' : '-',
            bold: true,
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final int amount;
  final Color color;
  final String prefix;
  final bool bold;

  const _StatRow({
    required this.label,
    required this.amount,
    required this.color,
    required this.prefix,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
        Text(
          '$prefix${formatAmountFull(amount)} SDG',
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
          ),
          textDirection: TextDirection.ltr,
        ),
      ],
    );
  }
}

class _CategoryBreakdown extends StatelessWidget {
  final Map<TransactionCategory, int> categories;
  final int total;

  const _CategoryBreakdown({
    required this.categories,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: sorted.map((e) {
        final pct = total > 0 ? e.value / total : 0.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    e.key.arabicLabel,
                    style: const TextStyle(fontSize: 13),
                  ),
                  Text(
                    '${formatAmountFull(e.value)} SDG',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    textDirection: TextDirection.ltr,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct.clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: const Color(0xFFE0E0E0),
                  valueColor: const AlwaysStoppedAnimation(kExpenseColor),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
