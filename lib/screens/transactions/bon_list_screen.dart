import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../models/bon.dart';
import '../../models/transaction_status.dart';
import '../../providers/app_data_provider.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/search_bar_field.dart';
import '../../widgets/status_badge.dart';

class BonListScreen extends StatefulWidget {
  const BonListScreen({super.key});

  @override
  State<BonListScreen> createState() => _BonListScreenState();
}

class _BonListScreenState extends State<BonListScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final bons = context.watch<AppDataProvider>().bons;
    final filtered = bons.where((bon) {
      final q = _search.toLowerCase();
      return bon.customerName.toLowerCase().contains(q) ||
          bon.id.toLowerCase().contains(q) ||
          bon.status.label.toLowerCase().contains(q);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        children: [
          SearchBarField(
            hintText: 'Cari bon',
            onChanged: (value) => setState(() => _search = value),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: filtered.isEmpty
                ? const EmptyState(
                    title: 'Belum ada bon',
                    subtitle:
                        'Tambahkan data bon untuk mencatat piutang atau pinjaman usaha.',
                    icon: Icons.note_alt_outlined,
                  )
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final bon = filtered[index];
                      return _BonCard(bon: bon);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _BonCard extends StatelessWidget {
  final Bon bon;

  const _BonCard({required this.bon});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        onTap: () => AppRoutes.push(
          context,
          AppRoutes.bonDetail,
          arguments: bon.id,
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
                      'Bon ${bon.id}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  StatusBadge(status: bon.status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.person_outline_rounded, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(bon.customerName)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text(AppFormatters.date(bon.date)),
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
                      AppFormatters.currency(bon.amount),
                      style: const TextStyle(fontWeight: FontWeight.w800),
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
