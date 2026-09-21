import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import '../../core/models/transaction.dart';
import '../../core/notifiers/transaction_notifier.dart';
import '../../app/theme.dart';
import 'transaction_form_screen.dart';

class TransactionDetailScreen extends StatelessWidget {
  final Transaction transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final isIncome = t.type == TransactionType.income;
    final amountColor = t.type.isDebt
        ? Colors.orange[800]!
        : (isIncome ? kIncomeColor : kExpenseColor);
    final sign = isIncome ? '+' : (t.type.isDebt ? '' : '-');

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل العملية'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'تعديل',
            onPressed: () async {
              final edited = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => TransactionFormScreen(existing: t),
                ),
              );
              if (edited == true && context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'حذف',
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Text(
              '$sign${formatAmountFull(t.amount)} ${t.currency}',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: amountColor,
              ),
              textDirection: TextDirection.ltr,
            ),
          ),
          const SizedBox(height: 8),
          Center(child: _TypeBadge(type: t.type)),
          const SizedBox(height: 24),
          _DetailCard(
            children: [
              if (t.partyName != null)
                _Row(label: 'الجهة / الشخص', value: t.partyName!),
              if (t.category != null)
                _Row(label: 'التصنيف', value: t.category!.arabicLabel),
              _Row(label: 'طريقة الدفع', value: t.paymentMethod.arabicLabel),
              _Row(
                label: 'التاريخ',
                value: DateFormat('yyyy/MM/dd').format(t.transactionDate),
                valueLtr: true,
              ),
              if (t.reference != null && t.reference!.isNotEmpty)
                _Row(label: 'المرجع', value: t.reference!, valueLtr: true),
              if (t.note != null && t.note!.isNotEmpty)
                _Row(label: 'ملاحظة', value: t.note!),
              _Row(label: 'المصدر', value: _sourceLabel(t.source)),
              _Row(
                label: 'تاريخ الإنشاء',
                value: DateFormat('yyyy/MM/dd HH:mm').format(t.createdAt),
                valueLtr: true,
              ),
            ],
          ),
          if (t.sourceText != null && t.sourceText!.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'النص الأصلي',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Color(0xFF6B6B6B),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              width: double.infinity,
              child: Text(
                t.sourceText!,
                style: const TextStyle(fontSize: 13, height: 1.5),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف العملية؟'),
        content: const Text('لا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: kExpenseColor),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed == true && context.mounted) {
        await QeedaScope.of(context).remove(transaction.id!);
        if (context.mounted) Navigator.of(context).pop();
      }
    });
  }

  String _sourceLabel(String src) {
    switch (src) {
      case 'text_import':
        return 'استيراد نص';
      case 'image_import':
        return 'استيراد صورة';
      default:
        return 'إدخال يدوي';
    }
  }
}

class _TypeBadge extends StatelessWidget {
  final TransactionType type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (type) {
      case TransactionType.income:
        bg = const Color(0xFFE8F5E9);
        fg = kIncomeColor;
      case TransactionType.expense:
        bg = const Color(0xFFFFEBEE);
        fg = kExpenseColor;
      default:
        bg = const Color(0xFFFFF3E0);
        fg = Colors.orange[800]!;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        type.arabicLabel,
        style: TextStyle(
          color: fg,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final List<Widget> children;
  const _DetailCard({required this.children});

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              const Divider(height: 1, indent: 16, endIndent: 16),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool valueLtr;

  const _Row({required this.label, required this.value, this.valueLtr = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF6B6B6B), fontSize: 13),
          ),
          Flexible(
            child: Text(
              value,
              textDirection:
                  valueLtr ? TextDirection.ltr : null,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
