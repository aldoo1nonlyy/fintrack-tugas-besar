import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../models/transaction_status.dart';
import '../../providers/app_data_provider.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../widgets/info_tile.dart';
import '../../widgets/status_badge.dart';

class HutangUsahaDetailScreen extends StatelessWidget {
  final String hutangUsahaId;

  const HutangUsahaDetailScreen({super.key, required this.hutangUsahaId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppDataProvider>();
    final hutangUsaha = provider.findHutangUsahaById(hutangUsahaId);

    if (hutangUsaha == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Hutang Usaha')),
        body: const Center(child: Text('Hutang Usaha tidak ditemukan')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Hutang Usaha')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                          hutangUsaha.number,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                      StatusBadge(status: hutangUsaha.status),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Total hutang usaha ${AppFormatters.currency(hutangUsaha.amount)}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InfoTile(
                      label: 'Suplier/Kreditur',
                      value: hutangUsaha.supplierName,
                      icon: Icons.person_outline,
                    ),
                    InfoTile(
                      label: 'Tanggal',
                      value: AppFormatters.date(hutangUsaha.date),
                      icon: Icons.calendar_today_outlined,
                    ),
                    InfoTile(
                      label: 'Nominal',
                      value: AppFormatters.currency(hutangUsaha.amount),
                      icon: Icons.payments_outlined,
                    ),
                    InfoTile(
                      label: 'Catatan',
                      value: hutangUsaha.notes.isEmpty ? '-' : hutangUsaha.notes,
                      icon: Icons.notes_outlined,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (hutangUsaha.status != TransactionStatus.paid)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.read<AppDataProvider>().markHutangUsahaAsPaid(hutangUsaha.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Hutang Usaha ditandai lunas')),
                    );
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Tandai Lunas'),
                ),
              ),
            if (hutangUsaha.status != TransactionStatus.paid) const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => AppRoutes.push(
                      context,
                      AppRoutes.hutangUsahaForm,
                      arguments: hutangUsaha,
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
                              title: const Text('Hapus Hutang Usaha'),
                              content: const Text('Yakin ingin mengHapus Hutang Usaha ini?'),
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

                      context.read<AppDataProvider>().deleteHutangUsaha(hutangUsaha.id);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Hutang Usaha berhasil dihapus')),
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
