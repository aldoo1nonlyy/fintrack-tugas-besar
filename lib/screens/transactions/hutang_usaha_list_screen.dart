import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../models/hutang_usaha.dart';
import '../../models/transaction_status.dart';
import '../../models/financial_entry.dart';
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
    final provider = context.watch<AppDataProvider>();
    final hutangUsahas = provider.hutangUsahas;
    final manualEntries = provider.financialEntries
        .where((e) => e.type == FinancialEntryType.payable && e.sourceId == null)
        .toList();

    final List<dynamic> combinedList = [...hutangUsahas, ...manualEntries];

    final filtered = combinedList.where((item) {
      final q = _search.toLowerCase();
      if (item is HutangUsaha) {
        return item.supplierName.toLowerCase().contains(q) ||
            item.number.toLowerCase().contains(q) ||
            item.status.label.toLowerCase().contains(q);
      } else if (item is FinancialEntry) {
        return item.title.toLowerCase().contains(q) ||
            item.description.toLowerCase().contains(q);
      }
      return false;
    }).toList();

    filtered.sort((a, b) {
      final dateA = a is HutangUsaha ? a.date : (a as FinancialEntry).date;
      final dateB = b is HutangUsaha ? b.date : (b as FinancialEntry).date;
      return dateB.compareTo(dateA);
    });

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
                      final item = filtered[index];
                      if (item is HutangUsaha) {
                        return _HutangUsahaCard(hutangUsaha: item);
                      } else if (item is FinancialEntry) {
                        return _ManualHutangCard(entry: item);
                      }
                      return const SizedBox();
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

class _ManualHutangCard extends StatelessWidget {
  final FinancialEntry entry;

  const _ManualHutangCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        onTap: () => AppRoutes.push(context, AppRoutes.financialEntryDetail, arguments: entry.id),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: const Text('Manual', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.orange)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.notes_rounded, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(entry.description.isEmpty ? 'Tidak ada catatan' : entry.description)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(AppFormatters.date(entry.date))),
                  if (entry.status != null) ...[
                    StatusBadge(status: entry.status!),
                  ],
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
                      AppFormatters.currency(entry.amount),
                      style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.error),
                    ),
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
