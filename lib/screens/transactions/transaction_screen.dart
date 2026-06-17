import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../providers/app_data_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/search_bar_field.dart';
import 'combined_transaction_list_screen.dart';
import 'hutang_usaha_list_screen.dart';

class TransactionScreen extends StatelessWidget {
  const TransactionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Transaksi'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Semua'),
              Tab(text: 'Invoice'),
              Tab(text: 'Bon'),
              Tab(text: 'Hutang Toko'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            CombinedTransactionListScreen(),
            _TransactionTab(filterType: 'Invoice'),
            _TransactionTab(filterType: 'Bon'),
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
              subtitle: const Text('Catatan piutang sederhana'),
              onTap: () {
                Navigator.pop(context);
                AppRoutes.push(context, AppRoutes.bonForm);
              },
            ),

            ListTile(
              leading: const Icon(Icons.business_rounded, color: Colors.purple),
              title: const Text('Hutang Toko (Usaha)'),
              subtitle: const Text('Catatan hutang ke supplier'),
              onTap: () {
                Navigator.pop(context);
                AppRoutes.push(context, AppRoutes.hutangUsahaForm);
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

class _TransactionTab extends StatefulWidget {
  final String filterType;
  const _TransactionTab({required this.filterType});

  @override
  State<_TransactionTab> createState() => _TransactionTabState();
}

class _TransactionTabState extends State<_TransactionTab> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppDataProvider>();
    final invoices = provider.invoices;
    final bons = provider.bons;

    final List<_TransactionItem> items = [];
    if (widget.filterType == 'Invoice') {
      for (final inv in invoices) {
        items.add(_TransactionItem(
          id: inv.id,
          title: inv.number,
          subtitle: inv.customerName,
          date: inv.date,
          amount: inv.total,
          type: 'Invoice',
          status: inv.status,
        ));
      }
    } else if (widget.filterType == 'Bon') {
      for (final bon in bons) {
        items.add(_TransactionItem(
          id: bon.id,
          title: bon.customerName,
          subtitle: 'Bon',
          date: bon.date,
          amount: bon.amount,
          type: 'Bon',
          status: bon.status,
        ));
      }
    }
    items.sort((a, b) => b.date.compareTo(a.date));

    final filteredItems = items.where((item) {
      if (_search.isEmpty) return true;
      final q = _search.toLowerCase();
      return item.title.toLowerCase().contains(q) ||
             item.subtitle.toLowerCase().contains(q);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        children: [
          SearchBarField(
            hintText: 'Cari ${widget.filterType}',
            onChanged: (value) => setState(() => _search = value),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: filteredItems.isEmpty
                ? Center(
                    child: Text('Belum ada transaksi ${widget.filterType}'),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: filteredItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
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
                AppRoutes.push(context, AppRoutes.invoiceDetail, arguments: item.id);
              } else {
                AppRoutes.push(context, AppRoutes.bonDetail, arguments: item.id);
              }
            },
          ),
        );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _TransactionItem {
  final String id;
  final String title;
  final String subtitle;
  final DateTime date;
  final double amount;
  final String type;
  final dynamic status;

  _TransactionItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.amount,
    required this.type,
    required this.status,
  });
}
