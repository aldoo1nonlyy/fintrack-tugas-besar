import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../models/product_item.dart';
import '../../models/transaction_status.dart';
import '../../providers/app_data_provider.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_badge.dart';

class ProductDetailScreen extends StatelessWidget {
  final ProductItem product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppDataProvider>();
    
    // Find all invoices containing this product
    final invoiceMatches = provider.invoices.where((inv) => 
      inv.items.any((item) => item.itemName == product.name)
    ).map((inv) {
      final line = inv.items.firstWhere((item) => item.itemName == product.name);
      return {
        'id': inv.id,
        'doc_number': inv.number,
        'customer': inv.customerName,
        'qty': line.qty,
        'price': line.price,
        'date': inv.date,
        'status': inv.status,
        'type': 'Invoice',
        'route': AppRoutes.invoiceDetail,
      };
    }).toList();

    // Find all bons containing this product
    final bonMatches = provider.bons.where((bon) => 
      bon.items.any((item) => item.itemName == product.name)
    ).map((bon) {
      final line = bon.items.firstWhere((item) => item.itemName == product.name);
      return {
        'id': bon.id,
        'doc_number': 'Bon ${bon.id}',
        'customer': bon.customerName,
        'qty': line.qty,
        'price': line.price,
        'date': bon.date,
        'status': bon.status,
        'type': 'Bon',
        'route': AppRoutes.bonDetail,
      };
    }).toList();

    final history = [...invoiceMatches, ...bonMatches];
    history.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

    // Calculate totals
    int totalQtySold = 0;
    int totalQtyBon = 0;

    for (var item in history) {
      if (item['type'] == 'Invoice') {
        totalQtySold += item['qty'] as int;
      } else if (item['type'] == 'Bon') {
        totalQtyBon += item['qty'] as int;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail & Riwayat Barang'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              AppRoutes.push(context, AppRoutes.productForm, arguments: product);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final shouldDelete = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Hapus Barang'),
                      content: const Text('Yakin ingin menghapus barang ini?'),
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

              context.read<AppDataProvider>().deleteProduct(product.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Barang berhasil dihapus')),
              );
            },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(Icons.inventory_2_rounded, color: Theme.of(context).colorScheme.primary, size: 40),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            if (product.category != null && product.category!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(product.category!, style: const TextStyle(color: AppColors.mutedText)),
                            ],
                            const SizedBox(height: 8),
                            Text(
                              AppFormatters.currency(product.price),
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Telah Terjual',
                          value: totalQtySold.toString(),
                          icon: Icons.check_circle_outline,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: 'Bon',
                          value: totalQtyBon.toString(),
                          icon: Icons.receipt_long,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(AppSpacing.screenPadding, 24, AppSpacing.screenPadding, 8),
              child: Text('Riwayat Transaksi', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            ),
          ),
          if (history.isEmpty)
            const SliverFillRemaining(
              child: EmptyState(
                icon: Icons.history,
                title: 'Belum ada riwayat',
                subtitle: 'Barang ini belum pernah digunakan dalam transaksi apapun.',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = history[index];
                    final isHutang = item['type'] == 'Hutang';
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        onTap: () {
                          AppRoutes.push(context, item['route'] as String, arguments: item['id']);
                        },
                        leading: CircleAvatar(
                          backgroundColor: isHutang ? AppColors.error.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.1),
                          child: Icon(
                            isHutang ? Icons.money_off : Icons.receipt_long,
                            color: isHutang ? AppColors.error : AppColors.primary,
                          ),
                        ),
                        title: Text('${item['qty']}x terjual ke ${item['customer']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${item['doc_number']} • ${AppFormatters.date(item['date'] as DateTime)}'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              AppFormatters.currency((item['qty'] as int) * (item['price'] as double)),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isHutang ? AppColors.error : AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            StatusBadge(status: item['status'] as TransactionStatus),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: history.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 12),
          Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 4),
          Text(title, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
