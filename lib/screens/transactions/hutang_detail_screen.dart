import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../models/transaction_status.dart';
import '../../providers/app_data_provider.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../widgets/info_tile.dart';
import '../../widgets/status_badge.dart';

class HutangDetailScreen extends StatelessWidget {
  final String hutangId;

  const HutangDetailScreen({super.key, required this.hutangId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppDataProvider>();
    final hutang = provider.findHutangById(hutangId);

    if (hutang == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Hutang')),
        body: const Center(child: Text('Hutang tidak ditemukan')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Hutang')),
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
                          hutang.number,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                      StatusBadge(status: hutang.status),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Total tagihan ${AppFormatters.currency(hutang.total)}',
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
                      label: 'Pelanggan',
                      value: hutang.customerName,
                      icon: Icons.person_outline,
                    ),
                    InfoTile(
                      label: 'Tanggal',
                      value: AppFormatters.date(hutang.date),
                      icon: Icons.calendar_today_outlined,
                    ),
                    InfoTile(
                      label: 'Catatan',
                      value: hutang.notes.isEmpty ? '-' : hutang.notes,
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
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ...hutang.items.map(
                      (item) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFF),
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
                          AppFormatters.currency(hutang.total),
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
            const SizedBox(height: 20),
            if (hutang.status != TransactionStatus.paid)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.read<AppDataProvider>().markHutangAsPaid(hutang.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Hutang ditandai lunas')),
                    );
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Tandai Lunas'),
                ),
              ),
            if (hutang.status != TransactionStatus.paid) const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => AppRoutes.push(
                      context,
                      AppRoutes.hutangForm,
                      arguments: hutang,
                    ),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Export PDF masih placeholder UI.'),
                        ),
                      );
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
                          title: const Text('Hapus Hutang'),
                          content: const Text('Yakin ingin menghapus Hutang ini?'),
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

                  context.read<AppDataProvider>().deleteHutang(hutang.id);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Hutang berhasil dihapus')),
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
