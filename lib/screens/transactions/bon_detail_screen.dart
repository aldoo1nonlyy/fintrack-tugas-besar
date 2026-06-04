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

class BonDetailScreen extends StatelessWidget {
  final String bonId;

  const BonDetailScreen({super.key, required this.bonId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppDataProvider>();
    final bon = provider.findBonById(bonId);
    final footerText = provider.businessProfile.invoiceFooter.trim();

    if (bon == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Bon')),
        body: const Center(child: Text('Bon tidak ditemukan')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Bon')),
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
                  colors: [Color(0xFF0EA5E9), Color(0xFF2563EB)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Bon ${bon.id}',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                      StatusBadge(status: bon.status),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Total bon ${AppFormatters.currency(bon.amount)}',
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
                      value: bon.customerName,
                      icon: Icons.person_outline,
                    ),
                    InfoTile(
                      label: 'Tanggal',
                      value: AppFormatters.date(bon.date),
                      icon: Icons.calendar_today_outlined,
                    ),
                    InfoTile(
                      label: 'Nominal',
                      value: AppFormatters.currency(bon.amount),
                      icon: Icons.payments_outlined,
                    ),
                    InfoTile(
                      label: 'Catatan',
                      value: bon.notes.isEmpty ? '-' : bon.notes,
                      icon: Icons.notes_outlined,
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
                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.07),
                  border: Border.all(
                    color: const Color(0xFF0EA5E9).withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.format_quote_rounded,
                      color: const Color(0xFF0EA5E9).withValues(alpha: 0.6),
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
            if (bon.status != TransactionStatus.paid)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    context.read<AppDataProvider>().markBonAsPaid(bon.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Bon ditandai lunas')),
                    );
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Tandai Lunas'),
                ),
              ),
            if (bon.status != TransactionStatus.paid)
              const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => AppRoutes.push(
                      context,
                      AppRoutes.bonForm,
                      arguments: bon,
                    ),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final shouldDelete = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Hapus bon'),
                              content:
                                  const Text('Yakin ingin menghapus bon ini?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Batal'),
                                ),
                                ElevatedButton(
                                  onPressed: () =>
                                      Navigator.pop(context, true),
                                  child: const Text('Hapus'),
                                ),
                              ],
                            ),
                          ) ??
                          false;

                      if (!context.mounted || !shouldDelete) return;

                      context.read<AppDataProvider>().deleteBon(bon.id);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Bon berhasil dihapus')),
                      );
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Hapus'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
