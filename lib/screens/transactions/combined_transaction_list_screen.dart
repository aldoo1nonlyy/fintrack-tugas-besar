import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../providers/app_data_provider.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_badge.dart';

class CombinedTransactionListScreen extends StatelessWidget {
  const CombinedTransactionListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppDataProvider>();
    final transactions = provider.combinedDocumentTransactions;

    if (transactions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.screenPadding),
        child: EmptyState(
          icon: Icons.receipt_long_outlined,
          title: 'Belum ada transaksi',
          subtitle: 'Invoice dan bon yang dibuat akan tampil dalam satu daftar gabungan.',
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: transactions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = transactions[index];
        final isInvoice = item['type'] == 'Invoice';
        final isHutang = item['type'] == 'Hutang';
        final isHutangUsaha = item['type'] == 'Hutang Usaha';

        return Card(
          child: ListTile(
            onTap: () {
              final route = isHutangUsaha
                  ? AppRoutes.hutangUsahaDetail
                  : (isHutang
                      ? AppRoutes.hutangDetail
                      : (isInvoice ? AppRoutes.invoiceDetail : AppRoutes.bonDetail));
              AppRoutes.push(
                context,
                route,
                arguments: item['id'],
              );
            },
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: (isHutang || isHutangUsaha)
                    ? AppColors.error.withValues(alpha: 0.10)
                    : Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isHutangUsaha
                    ? Icons.account_balance_wallet_rounded
                    : (isHutang
                        ? Icons.money_off_rounded
                        : (isInvoice ? Icons.receipt_long_rounded : Icons.note_alt_rounded)),
                color: (isHutang || isHutangUsaha)
                    ? AppColors.error
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
            title: Text(
              item['title'] as String,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${item['type']} • ${item['subtitle']} • ${AppFormatters.date(item['date'] as DateTime)}',
              ),
            ),
            trailing: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppFormatters.currency(item['amount'] as num),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: (isHutang || isHutangUsaha) ? AppColors.error : AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                StatusBadge(status: item['status']),
              ],
            ),
          ),
        );
      },
    );
  }
}
