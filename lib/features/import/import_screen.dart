import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/models/transaction.dart';
import '../../core/notifiers/transaction_notifier.dart';
import '../../core/services/parser_service.dart';
import '../../core/services/ocr_service.dart';
import '../../core/services/share_service.dart';
import '../../app/theme.dart';

class ImportScreen extends StatefulWidget {
  final SharedData shared;

  const ImportScreen({super.key, required this.shared});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  ParseResult? _parsed;
  bool _processingOcr = false;
  String? _ocrError;
  String? _displayText;

  final _amountCtrl = TextEditingController();
  final _partyCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  TransactionType _type = TransactionType.expense;
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (widget.shared.dataType == 'text' && widget.shared.text != null) {
      final result = ParserService.instance.parse(widget.shared.text!);
      _applyParsed(result);
      setState(() {
        _displayText = widget.shared.text;
        _parsed = result;
      });
    } else if (widget.shared.dataType == 'image' &&
        widget.shared.imagePath != null) {
      setState(() => _processingOcr = true);
      try {
        final text = await OcrService.instance
            .recognizeText(widget.shared.imagePath!);
        if (text != null && text.isNotEmpty) {
          final result = ParserService.instance.parse(text);
          _applyParsed(result);
          setState(() {
            _displayText = text;
            _parsed = result;
            _processingOcr = false;
          });
        } else {
          setState(() {
            _ocrError = 'تعذر قراءة الصورة. أدخل البيانات يدويًا.';
            _processingOcr = false;
          });
        }
      } catch (_) {
        setState(() {
          _ocrError = 'تعذر قراءة الصورة. أدخل البيانات يدويًا.';
          _processingOcr = false;
        });
      }
    }
  }

  void _applyParsed(ParseResult r) {
    if (r.amount != null && r.amount! > 0) {
      _amountCtrl.text = r.amount.toString();
    }
    if (r.partyName != null) _partyCtrl.text = r.partyName!;
    if (r.type != null) _type = r.type!;
    if (r.date != null) _date = r.date!;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _partyCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('استيراد عملية'),
        leading: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        leadingWidth: 70,
      ),
      body: _processingOcr
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('جارٍ قراءة الصورة...'),
                ],
              ),
            )
          : _buildForm(context),
    );
  }

  Widget _buildForm(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        if (_ocrError != null)
          _WarningBanner(message: _ocrError!)
        else
          const _ReviewBanner(),
        const SizedBox(height: 12),
        if (widget.shared.dataType == 'image' &&
            widget.shared.imagePath != null)
          _ImagePreview(path: widget.shared.imagePath!),
        if (_displayText != null) ...[
          const SizedBox(height: 12),
          _SourceTextCard(text: _displayText!),
        ],
        const SizedBox(height: 16),
        const Text(
          'البيانات المستخرجة',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 10),
        _TypeSel(
          selected: _type,
          onChanged: (t) => setState(() => _type = t),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _amountCtrl,
          keyboardType: TextInputType.number,
          textDirection: TextDirection.ltr,
          decoration: InputDecoration(
            labelText: 'المبلغ *',
            suffixText: 'SDG',
            helperText:
                (_parsed?.isAmountConfident == false &&
                    _amountCtrl.text.isNotEmpty)
                    ? 'راجع المبلغ'
                    : null,
            helperStyle: const TextStyle(color: Colors.orange),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _partyCtrl,
          decoration: const InputDecoration(labelText: 'الجهة / الشخص'),
        ),
        const SizedBox(height: 12),
        _DateSel(
          date: _date,
          onChanged: (d) => setState(() => _date = d),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _noteCtrl,
          decoration: const InputDecoration(labelText: 'ملاحظة'),
          maxLines: 2,
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
    );
  }

  Future<void> _save() async {
    final amountText = _amountCtrl.text.trim();
    if (amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('المبلغ مطلوب')),
      );
      return;
    }
    final amount = int.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('المبلغ يجب أن يكون أكبر من صفر')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final party = _partyCtrl.text.trim();
      final note = _noteCtrl.text.trim();
      final source = widget.shared.dataType == 'image'
          ? 'image_import'
          : 'text_import';
      final t = Transaction(
        type: _type,
        amount: amount,
        partyName: party.isEmpty ? null : party,
        transactionDate: _date,
        createdAt: DateTime.now(),
        source: source,
        sourceText: _displayText,
        note: note.isEmpty ? null : note,
      );
      await QeedaScope.of(context).add(t);
      if (mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _ReviewBanner extends StatelessWidget {
  const _ReviewBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFCC02)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: Color(0xFFE65100)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'راجع البيانات قبل الحفظ',
              style: TextStyle(
                color: Color(0xFFE65100),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WarningBanner extends StatelessWidget {
  final String message;
  const _WarningBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kExpenseColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_outlined, size: 18, color: kExpenseColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: kExpenseColor, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceTextCard extends StatelessWidget {
  final String text;
  const _SourceTextCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'النص الأصلي',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF6B6B6B),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            text,
            textDirection: TextDirection.rtl,
            style: const TextStyle(fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  final String path;
  const _ImagePreview({required this.path});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 200),
        child: Image.file(
          File(path),
          fit: BoxFit.contain,
          width: double.infinity,
          errorBuilder: (ctx, err, trace) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}

class _TypeSel extends StatelessWidget {
  final TransactionType selected;
  final ValueChanged<TransactionType> onChanged;

  const _TypeSel({required this.selected, required this.onChanged});

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

class _DateSel extends StatelessWidget {
  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  const _DateSel({required this.date, required this.onChanged});

  @override
  Widget build(BuildContext context) {
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
        child: Text(
          '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}',
          textDirection: TextDirection.ltr,
        ),
      ),
    );
  }
}
