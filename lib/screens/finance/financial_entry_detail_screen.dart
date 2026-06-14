import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/financial_entry.dart';
import '../../models/transaction_status.dart';
import '../../providers/app_data_provider.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../widgets/status_badge.dart';
import 'finance_screen.dart'; // For showFinanceFormSheet

class FinancialEntryDetailScreen extends StatelessWidget {
  final String id;

  const FinancialEntryDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppDataProvider>();
    final entry = provider.financialEntries.where((e) => e.id == id).firstOrNull;

    if (entry == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Catatan')),
        body: const Center(child: Text('Catatan tidak ditemukan')),
      );
    }

    final isDebt = entry.type == FinancialEntryType.payable || entry.type == FinancialEntryType.receivable;
    final isUnpaid = entry.status == TransactionStatus.unpaid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Catatan Manual'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => showFinanceFormSheet(context, entry: entry),
            tooltip: 'Edit Catatan',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Hapus Catatan'),
                  content: const Text('Yakin ingin menghapus catatan ini?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Batal'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                      child: const Text('Hapus'),
                    ),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                provider.deleteFinancialEntry(id);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Catatan berhasil dihapus')),
                );
              }
            },
            tooltip: 'Hapus Catatan',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      entry.type == FinancialEntryType.income
                          ? Icons.south_west_rounded
                          : (entry.type == FinancialEntryType.expense
                              ? Icons.north_east_rounded
                              : (entry.type == FinancialEntryType.payable ? Icons.money_off_rounded : Icons.account_balance_wallet_rounded)),
                      size: 32,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppFormatters.currency(entry.amount),
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Catatan ${entry.type.label} Manual',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Detail Catatan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            _DetailRow(label: 'Judul', value: entry.title),
            _DetailRow(label: 'Tanggal', value: AppFormatters.date(entry.date)),
            if (isDebt && entry.status != null) ...[
              _DetailRow(
                label: 'Status',
                value: entry.status!.label,
                customValueWidget: StatusBadge(status: entry.status!),
              ),
            ],
            const SizedBox(height: 8),
            const Text(
              'Keterangan',
              style: TextStyle(fontWeight: FontWeight.w700, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(entry.description.isEmpty ? '-' : entry.description),
            
            if (isDebt && isUnpaid) ...[
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () {
                    provider.markFinancialEntryAsPaid(id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Catatan berhasil ditandai Lunas')),
                    );
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Tandai Lunas'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Widget? customValueWidget;

  const _DetailRow({required this.label, required this.value, this.customValueWidget});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.grey),
            ),
          ),
          Expanded(
            flex: 3,
            child: customValueWidget ?? Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
