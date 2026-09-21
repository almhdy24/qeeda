import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/transaction.dart';

class ExportService {
  static ExportService? _instance;
  ExportService._();
  static ExportService get instance {
    _instance ??= ExportService._();
    return _instance!;
  }

  Future<void> exportCsv(List<Transaction> transactions) async {
    final buffer = StringBuffer();
    buffer.writeln(
      'id,type,amount,currency,party_name,category,payment_method,'
      'note,reference,transaction_date,source',
    );

    for (final t in transactions) {
      buffer.writeln([
        t.id ?? '',
        t.type.name,
        t.amount,
        t.currency,
        _escape(t.partyName),
        t.category?.name ?? '',
        t.paymentMethod.name,
        _escape(t.note),
        _escape(t.reference),
        t.transactionDate.toIso8601String(),
        t.source,
      ].join(','));
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/qeeda_export.csv');
    await file.writeAsString(buffer.toString(), encoding: SystemEncoding());

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      subject: 'قيدة - تصدير العمليات',
    );
  }

  String _escape(String? value) {
    if (value == null || value.isEmpty) return '';
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
