import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../models/customer.dart';
import '../../models/transaction_status.dart';
import '../../providers/app_data_provider.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_badge.dart';

class CustomerDetailScreen extends StatelessWidget {
  final Customer customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppDataProvider>();

    // Retrieve all transactions for this customer
    final List<Map<String, dynamic>> userTransactions = [];

    // 1. Invoices
    for (final inv in provider.invoices.where((e) => e.customerId == customer.id)) {
      userTransactions.add({
        'id': inv.id,
        'doc_number': inv.number,
        'amount': inv.total,
        'date': inv.date,
        'status': inv.status,
        'type': 'Invoice',
        'route': AppRoutes.invoiceDetail,
      });
    }

    // 2. Bons
    for (final bon in provider.bons.where((e) => e.customerName == customer.name)) {
      userTransactions.add({
        'id': bon.id,
        'doc_number': 'Bon ${bon.id}',
        'amount': bon.amount,
        'date': bon.date,
        'status': bon.status,
        'type': 'Bon',
        'route': AppRoutes.bonDetail,
      });
    }


    userTransactions.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

    // Calculate Unpaid Debts (Total Hutang Pelanggan)
    double totalUnpaidDebt = 0;
    int unpaidCount = 0;

    for (var trx in userTransactions) {
      if (trx['status'] == TransactionStatus.unpaid || trx['status'] == TransactionStatus.overdue) {
        totalUnpaidDebt += trx['amount'] as double;
        unpaidCount++;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buku Hutang & Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              AppRoutes.push(context, AppRoutes.customerForm, arguments: customer);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final shouldDelete = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Hapus Pelanggan'),
                      content: const Text('Yakin ingin menghapus pelanggan ini?'),
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

              context.read<AppDataProvider>().deleteCustomer(customer.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pelanggan berhasil dihapus')),
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
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3867F4), Color(0xFF6A5AF9)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 24,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              customer.name,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(customer.phone, style: const TextStyle(color: AppColors.mutedText)),
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: totalUnpaidDebt > 0 ? AppColors.error.withValues(alpha: 0.1) : AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: totalUnpaidDebt > 0 ? AppColors.error.withValues(alpha: 0.3) : AppColors.success.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              totalUnpaidDebt > 0 ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                              color: totalUnpaidDebt > 0 ? AppColors.error : AppColors.success,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Total Tunggakan / Hutang',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: totalUnpaidDebt > 0 ? AppColors.error : AppColors.success,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppFormatters.currency(totalUnpaidDebt),
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: totalUnpaidDebt > 0 ? AppColors.error : AppColors.success,
                              ),
                        ),
                        if (unpaidCount > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Dari $unpaidCount transaksi belum lunas',
                            style: TextStyle(color: AppColors.error.withValues(alpha: 0.8), fontWeight: FontWeight.w600),
                          ),
                        ]
                      ],
                    ),
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
          if (userTransactions.isEmpty)
            const SliverFillRemaining(
              child: EmptyState(
                icon: Icons.receipt_long,
                title: 'Belum ada transaksi',
                subtitle: 'Pelanggan ini belum pernah melakukan transaksi hutang, bon, maupun invoice.',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = userTransactions[index];
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
                        title: Text('${item['type']} ${item['doc_number']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(AppFormatters.date(item['date'] as DateTime)),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              AppFormatters.currency(item['amount'] as double),
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
                  childCount: userTransactions.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_customer_detail',
        onPressed: () {
          // Defaultnya buat bon baru untuk user ini jika menekan FAB
          AppRoutes.push(context, AppRoutes.bonForm);
        },
        icon: const Icon(Icons.add),
        label: const Text('Buat Bon'),
        backgroundColor: AppColors.error,
        foregroundColor: Colors.white,
      ),
    );
  }
}
