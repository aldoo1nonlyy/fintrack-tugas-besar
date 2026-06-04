import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../models/transaction_status.dart';
import '../../providers/app_data_provider.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../widgets/info_tile.dart';
import '../../widgets/status_badge.dart';
import '../../services/invoice_pdf_service.dart';

class InvoiceDetailScreen extends StatelessWidget {
  final String invoiceId;

  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppDataProvider>();
    final invoice = provider.findInvoiceById(invoiceId);
    final footerText = provider.businessProfile.invoiceFooter.trim();

    if (invoice == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Invoice')),
        body: const Center(child: Text('Invoice tidak ditemukan')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Invoice')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  colors: [Color(0xFF3867F4), Color(0xFF6A5AF9)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          invoice.number,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                      StatusBadge(status: invoice.status),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Total tagihan ${AppFormatters.currency(invoice.total)}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Info card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InfoTile(
                      label: 'Pelanggan',
                      value: invoice.customerName,
                      icon: Icons.person_outline,
                    ),
                    InfoTile(
                      label: 'Tanggal',
                      value: AppFormatters.date(invoice.date),
                      icon: Icons.calendar_today_outlined,
                    ),
                    InfoTile(
                      label: 'Catatan',
                      value: invoice.notes.isEmpty ? '-' : invoice.notes,
                      icon: Icons.notes_outlined,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Daftar Barang',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),

            // Items card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ...invoice.items.map(
                      (item) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.surfaceContainerDark
                              : const Color(0xFFF8FAFF),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.itemName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${item.qty} x ${AppFormatters.currency(item.price)}',
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              AppFormatters.currency(item.subtotal),
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          AppFormatters.currency(invoice.total),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Footer usaha (hanya tampil jika tidak kosong) ──
            if (footerText.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: AppColors.primary.withValues(alpha: 0.07),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.format_quote_rounded,
                      color: AppColors.primary.withValues(alpha: 0.6),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        footerText,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: AppColors.mutedText,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Action buttons
            if (invoice.status != TransactionStatus.paid)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    context.read<AppDataProvider>().markInvoiceAsPaid(invoice.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invoice ditandai lunas')),
                    );
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Tandai Lunas'),
                ),
              ),
            if (invoice.status != TransactionStatus.paid)
              const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => AppRoutes.push(
                      context,
                      AppRoutes.invoiceForm,
                      arguments: invoice,
                    ),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      try {
                        await InvoicePdfService.exportInvoice(
                          context.read<AppDataProvider>(),
                          invoice,
                        );
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Gagal export PDF. Pastikan dependensi sudah terinstall.'),
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('Export PDF'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final shouldDelete = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Hapus invoice'),
                          content:
                              const Text('Yakin ingin menghapus invoice ini?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Batal'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Hapus'),
                            ),
                          ],
                        ),
                      ) ??
                      false;

                  if (!context.mounted || !shouldDelete) return;

                  context.read<AppDataProvider>().deleteInvoice(invoice.id);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invoice berhasil dihapus')),
                  );
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text('Hapus'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
