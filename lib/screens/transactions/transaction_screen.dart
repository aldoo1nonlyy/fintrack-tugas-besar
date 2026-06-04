import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../providers/app_data_provider.dart';
import 'combined_transaction_list_screen.dart';
import 'hutang_usaha_list_screen.dart';

class TransactionScreen extends StatelessWidget {
  const TransactionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Transaksi'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Semua'),
              Tab(text: 'Transaksi'),
              Tab(text: 'Hutang Toko'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            CombinedTransactionListScreen(),
            _TransactionTab(),
            HutangUsahaListScreen(),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'fab_transaction',
          onPressed: () => _showTransactionTypeDialog(context),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Buat Transaksi'),
        ),
      ),
    );
  }

  static void _showTransactionTypeDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Jenis Transaksi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.receipt_long_rounded, color: Colors.blue),
              title: const Text('Invoice'),
              subtitle: const Text('Tagihan untuk pelanggan'),
              onTap: () {
                Navigator.pop(context);
                AppRoutes.push(context, AppRoutes.invoiceForm);
              },
            ),
            ListTile(
              leading: const Icon(Icons.note_alt_rounded, color: Colors.orange),
              title: const Text('Bon'),
              subtitle: const Text('Catatan hutang/bon'),
              onTap: () {
                Navigator.pop(context);
                AppRoutes.push(context, AppRoutes.bonForm);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
        ],
      ),
    );
  }
}

class _TransactionTab extends StatelessWidget {
  const _TransactionTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppDataProvider>();
    final invoices = provider.invoices;
    final bons = provider.bons;

    final List<_TransactionItem> items = [];
    for (final inv in invoices) {
      items.add(_TransactionItem(
        title: inv.number,
        subtitle: inv.customerName,
        date: inv.date,
        amount: inv.total,
        type: 'Invoice',
        status: inv.status,
      ));
    }
    for (final bon in bons) {
      items.add(_TransactionItem(
        title: bon.customerName,
        subtitle: 'Bon',
        date: bon.date,
        amount: bon.amount,
        type: 'Bon',
        status: bon.status,
      ));
    }
    items.sort((a, b) => b.date.compareTo(a.date));

    if (items.isEmpty) {
      return const Center(
        child: Text('Belum ada transaksi Invoice atau Bon'),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        final isInvoice = item.type == 'Invoice';

        return Card(
          child: ListTile(
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (isInvoice ? Colors.blue : Colors.orange).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isInvoice ? Icons.receipt_long_rounded : Icons.note_alt_rounded,
                color: isInvoice ? Colors.blue : Colors.orange,
              ),
            ),
            title: Text(
              item.title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text('${item.subtitle} • ${item.date.day}/${item.date.month}/${item.date.year}'),
            trailing: Text(
              'Rp ${item.amount.toStringAsFixed(0)}',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: isInvoice ? Colors.blue : Colors.orange,
              ),
            ),
            onTap: () {
              if (isInvoice) {
                AppRoutes.push(context, AppRoutes.invoiceDetail, arguments: item.title);
              } else {
                AppRoutes.push(context, AppRoutes.bonDetail, arguments: item.title);
              }
            },
          ),
        );
      },
    );
  }
}

class _TransactionItem {
  final String title;
  final String subtitle;
  final DateTime date;
  final double amount;
  final String type;
  final dynamic status;

  _TransactionItem({
    required this.title,
    required this.subtitle,
    required this.date,
    required this.amount,
    required this.type,
    required this.status,
  });
}
