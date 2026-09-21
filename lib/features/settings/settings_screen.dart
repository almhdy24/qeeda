import 'package:flutter/material.dart';
import '../../core/notifiers/transaction_notifier.dart';
import '../../core/services/export_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        children: [
          const _SectionTitle(title: 'البيانات'),
          ListTile(
            leading: const Icon(Icons.file_download_outlined),
            title: const Text('تصدير البيانات'),
            subtitle: const Text('تصدير العمليات كملف CSV'),
            onTap: () => _export(context),
          ),
          const Divider(height: 1),
          const _SectionTitle(title: 'العملة'),
          const ListTile(
            leading: Icon(Icons.currency_exchange),
            title: Text('العملة الافتراضية'),
            subtitle: Text('جنيه سوداني (SDG)'),
          ),
          const Divider(height: 1),
          const _SectionTitle(title: 'حول'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('قيدة'),
            subtitle: Text('سجل المعاملات المالية الشخصية\nالإصدار 1.0.0'),
            isThreeLine: true,
          ),
          const ListTile(
            leading: Icon(Icons.lock_outline),
            title: Text('الخصوصية'),
            subtitle: Text(
              'جميع البيانات مخزنة على جهازك فقط.\nلا يوجد إرسال للإنترنت.',
            ),
            isThreeLine: true,
          ),
        ],
      ),
    );
  }

  Future<void> _export(BuildContext context) async {
    try {
      final notifier = QeedaScope.of(context);
      final all = notifier.transactions;
      if (all.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('لا توجد عمليات للتصدير')),
          );
        }
        return;
      }
      await ExportService.instance.exportCsv(all);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر تصدير البيانات')),
        );
      }
    }
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF6B6B6B),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
