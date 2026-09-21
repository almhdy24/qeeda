import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' show DateFormat;
import '../../core/models/transaction.dart';
import '../../core/notifiers/transaction_notifier.dart';

class TransactionFormScreen extends StatefulWidget {
  final Transaction? existing;
  final Transaction? prefilled;

  const TransactionFormScreen({super.key, this.existing, this.prefilled});

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _partyCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _refCtrl = TextEditingController();

  late TransactionType _type;
  TransactionCategory? _category;
  PaymentMethod _method = PaymentMethod.unknown;
  late DateTime _date;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final src = widget.existing ?? widget.prefilled;
    _type = src?.type ?? TransactionType.expense;
    _category = src?.category;
    _method = src?.paymentMethod ?? PaymentMethod.unknown;
    _date = src?.transactionDate ?? DateTime.now();
    if (src != null) {
      if (src.amount > 0) _amountCtrl.text = src.amount.toString();
      _partyCtrl.text = src.partyName ?? '';
      _noteCtrl.text = src.note ?? '';
      _refCtrl.text = src.reference ?? '';
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _partyCtrl.dispose();
    _noteCtrl.dispose();
    _refCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'تعديل العملية' : 'إضافة عملية'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _TypeSelector(
              selected: _type,
              onChanged: (t) => setState(() => _type = t),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(
                labelText: 'المبلغ *',
                suffixText: 'SDG',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'المبلغ مطلوب';
                final n = int.tryParse(v.trim());
                if (n == null || n <= 0) {
                  return 'المبلغ يجب أن يكون أكبر من صفر';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _partyCtrl,
              decoration: const InputDecoration(labelText: 'الجهة / الشخص'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<TransactionCategory?>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'التصنيف'),
              items: [
                const DropdownMenuItem(value: null, child: Text('بدون تصنيف')),
                ...TransactionCategory.values.map(
                  (c) => DropdownMenuItem(value: c, child: Text(c.arabicLabel)),
                ),
              ],
              onChanged: (c) => setState(() => _category = c),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<PaymentMethod>(
              initialValue: _method,
              decoration: const InputDecoration(labelText: 'طريقة الدفع'),
              items: PaymentMethod.values
                  .map(
                    (m) => DropdownMenuItem(
                      value: m,
                      child: Text(m.arabicLabel),
                    ),
                  )
                  .toList(),
              onChanged: (m) =>
                  setState(() => _method = m ?? PaymentMethod.unknown),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _refCtrl,
              decoration: const InputDecoration(labelText: 'المرجع'),
              textDirection: TextDirection.ltr,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteCtrl,
              decoration: const InputDecoration(labelText: 'ملاحظة'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            _DateField(
              date: _date,
              onChanged: (d) => setState(() => _date = d),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('حفظ العملية'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final amount = int.parse(_amountCtrl.text.trim());
      final party = _partyCtrl.text.trim();
      final note = _noteCtrl.text.trim();
      final ref = _refCtrl.text.trim();
      final notifier = QeedaScope.of(context);
      final now = DateTime.now();

      if (widget.existing != null) {
        await notifier.edit(
          widget.existing!.copyWith(
            type: _type,
            amount: amount,
            partyName: party.isEmpty ? null : party,
            category: _category,
            paymentMethod: _method,
            note: note.isEmpty ? null : note,
            reference: ref.isEmpty ? null : ref,
            transactionDate: _date,
          ),
        );
      } else {
        await notifier.add(
          Transaction(
            type: _type,
            amount: amount,
            partyName: party.isEmpty ? null : party,
            category: _category,
            paymentMethod: _method,
            note: note.isEmpty ? null : note,
            reference: ref.isEmpty ? null : ref,
            transactionDate: _date,
            createdAt: now,
            source: widget.prefilled?.source ?? 'manual',
            sourceText: widget.prefilled?.sourceText,
          ),
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _TypeSelector extends StatelessWidget {
  final TransactionType selected;
  final ValueChanged<TransactionType> onChanged;

  const _TypeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<TransactionType>(
      segments: const [
        ButtonSegment(value: TransactionType.income, label: Text('استلام')),
        ButtonSegment(value: TransactionType.expense, label: Text('مصروف')),
        ButtonSegment(
          value: TransactionType.debtReceivable,
          label: Text('لي'),
        ),
        ButtonSegment(
          value: TransactionType.debtPayable,
          label: Text('عليّ'),
        ),
      ],
      selected: {selected},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}

class _DateField extends StatelessWidget {
  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  const _DateField({required this.date, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final formatted = DateFormat('yyyy/MM/dd').format(date);
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) onChanged(picked);
      },
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'التاريخ',
          suffixIcon: Icon(Icons.calendar_today, size: 18),
        ),
        child: Text(formatted, textDirection: TextDirection.ltr),
      ),
    );
  }
}
