import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../models/hutang_usaha.dart';
import '../../models/transaction_status.dart';
import '../../providers/app_data_provider.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/search_bar_field.dart';
import '../../widgets/status_badge.dart';

class HutangUsahaListScreen extends StatefulWidget {
  const HutangUsahaListScreen({super.key});

  @override
  State<HutangUsahaListScreen> createState() => _HutangUsahaListScreenState();
}

class _HutangUsahaListScreenState extends State<HutangUsahaListScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final hutangUsahas = context.watch<AppDataProvider>().hutangUsahas;
    final filtered = hutangUsahas.where((hu) {
      final q = _search.toLowerCase();
      return hu.supplierName.toLowerCase().contains(q) ||
          hu.number.toLowerCase().contains(q) ||
          hu.status.label.toLowerCase().contains(q);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        children: [
          SearchBarField(
            hintText: 'Cari hutang usaha',
            onChanged: (value) => setState(() => _search = value),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: filtered.isEmpty
                ? const EmptyState(
                    title: 'Belum ada hutang usaha',
                    subtitle:
                        'Tambahkan data hutang usaha kepada suplier.',
                    icon: Icons.account_balance_wallet_outlined,
                  )
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final hu = filtered[index];
                      return _HutangUsahaCard(hutangUsaha: hu);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _HutangUsahaCard extends StatelessWidget {
  final HutangUsaha hutangUsaha;

  const _HutangUsahaCard({required this.hutangUsaha});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        onTap: () => AppRoutes.push(
          context,
          AppRoutes.hutangUsahaDetail,
          arguments: hutangUsaha.id,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      hutangUsaha.number,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  StatusBadge(status: hutangUsaha.status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.business_rounded, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(hutangUsaha.supplierName)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text(AppFormatters.date(hutangUsaha.date)),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Text(
                      AppFormatters.currency(hutangUsaha.amount),
                      style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.error),
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
