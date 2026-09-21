import 'package:flutter/material.dart';
import '../../core/models/transaction.dart';
import '../../core/notifiers/transaction_notifier.dart';
import '../../app/theme.dart';
import '../transactions/transaction_detail_screen.dart';
import '../transactions/transaction_form_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: QeedaScope.of(context),
      builder: (context, _) {
        final n = QeedaScope.of(context);
        return Scaffold(
          appBar: AppBar(
            title: const Text('قيدة'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'إضافة عملية',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const TransactionFormScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          body: n.loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: n.load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _BalanceCard(
                        balance: n.balance,
                        income: n.totalIncome,
                        expense: n.totalExpense,
                      ),
                      const SizedBox(height: 20),
                      if (n.recentTransactions.isEmpty)
                        _EmptyDashboard(
                          onAdd: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const TransactionFormScreen(),
                            ),
                          ),
                        )
                      else ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'آخر العمليات',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...n.recentTransactions.map(
                          (t) => _RecentTile(transaction: t),
                        ),
                      ],
                    ],
                  ),
                ),
        );
      },
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final int balance;
  final int income;
  final int expense;

  const _BalanceCard({
    required this.balance,
    required this.income,
    required this.expense,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'الرصيد الإجمالي',
            style: TextStyle(
              color: Color(0xFF6B6B6B),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${formatAmountFull(balance)} SDG',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F0F0F),
            ),
            textDirection: TextDirection.ltr,
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  label: 'الدخل',
                  amount: income,
                  color: kIncomeColor,
                  prefix: '+',
                ),
              ),
              const SizedBox(
                height: 40,
                child: VerticalDivider(width: 1),
              ),
              Expanded(
                child: _SummaryItem(
                  label: 'المصروف',
                  amount: expense,
                  color: kExpenseColor,
                  prefix: '-',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final int amount;
  final Color color;
  final String prefix;

  const _SummaryItem({
    required this.label,
    required this.amount,
    required this.color,
    required this.prefix,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF6B6B6B),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$prefix${formatAmount(amount)} SDG',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
          textDirection: TextDirection.ltr,
        ),
      ],
    );
  }
}

class _RecentTile extends StatelessWidget {
  final Transaction transaction;

  const _RecentTile({required this.transaction});

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
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
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
                    ),
                  Text(
                    t.category?.arabicLabel ?? t.type.arabicLabel,
                    style: const TextStyle(
                      fontSize: 12,
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

class _EmptyDashboard extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyDashboard({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
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
            onPressed: onAdd,
            child: const Text('إضافة عملية'),
          ),
        ],
      ),
    );
  }
}
