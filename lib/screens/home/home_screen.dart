import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../providers/app_data_provider.dart';
import '../../services/tutorial_service.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/quick_action_tile.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/summary_card.dart';
import '../../widgets/tutorial_overlay.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  bool _showTutorial = false;
  late AnimationController _headerController;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _headerFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOut),
    );

    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutCubic),
    );

    _headerController.forward();
    _checkTutorial();
  }

  Future<void> _checkTutorial() async {
    final seen = await TutorialService.hasSeenTutorial();
    if (!seen && mounted) {
      // Small delay so the screen loads first
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) setState(() => _showTutorial = true);
    }
  }

  Future<void> _onTutorialDone() async {
    await TutorialService.markTutorialSeen();
    if (mounted) {
      setState(() => _showTutorial = false);
      HapticFeedback.mediumImpact();
    }
  }

  @override
  void dispose() {
    _headerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppDataProvider>();
    final financialSummary = provider.financialSummary;

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Dashboard'),
            actions: [
              // Tutorial hint button
              IconButton(
                onPressed: () => setState(() => _showTutorial = true),
                icon: const Icon(Icons.help_outline_rounded),
                tooltip: 'Panduan',
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Animated header banner
                FadeTransition(
                  opacity: _headerFade,
                  child: SlideTransition(
                    position: _headerSlide,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            offset: const Offset(0, 12),
                            blurRadius: 24,
                            spreadRadius: -4,
                          ),
                        ],
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primaryLight.withValues(alpha: 0.15),
                            AppColors.primary,
                            AppColors.primaryDark,
                          ],
                          stops: const [0.0, 0.3, 1.0],
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Decorative circles
                          Positioned(
                            right: -20,
                            top: -20,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 40,
                            bottom: -30,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text(
                                  'Ringkasan usaha hari ini',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Kelola invoice, bon, pelanggan, dan stok barang usaha dari satu aplikasi.',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      color: Colors.white,
                                      height: 1.2,
                                    ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Saldo ${AppFormatters.currency(financialSummary.balance)} • ${provider.totalInvoice} invoice • ${provider.totalBon} bon • ${provider.unpaidCount} menunggu pembayaran',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Colors.white.withValues(alpha: 0.85),
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sectionGap),

                // Staggered summary cards
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final childAspectRatio = width < 340 ? 0.95 : 1.12;
                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: childAspectRatio,
                      children: [
                        SummaryCard(
                          title: 'Total Invoice',
                          value: provider.totalInvoice.toString(),
                          icon: Icons.receipt_long_rounded,
                          animationDelay: 0,
                        ),
                        SummaryCard(
                          title: 'Total Bon',
                          value: provider.totalBon.toString(),
                          icon: Icons.note_alt_rounded,
                          animationDelay: 80,
                        ),
                        SummaryCard(
                          title: 'Belum Lunas',
                          value: provider.unpaidCount.toString(),
                          icon: Icons.pending_actions_rounded,
                          animationDelay: 160,
                        ),
                        SummaryCard(
                          title: 'Saldo Kas',
                          value: AppFormatters.currency(financialSummary.balance),
                          icon: Icons.account_balance_wallet_rounded,
                          animationDelay: 240,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                Text(
                  'Aksi cepat',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                QuickActionTile(
                  label: 'Buat Invoice Baru',
                  subtitle: 'Tambah tagihan pelanggan dengan lebih cepat',
                  icon: Icons.add_card_rounded,
                  onTap: () => AppRoutes.push(context, AppRoutes.invoiceForm),
                ),
                const SizedBox(height: 12),
                QuickActionTile(
                  label: 'Tambah Bon',
                  subtitle: 'Catat piutang atau pinjaman usaha',
                  icon: Icons.note_add_rounded,
                  onTap: () => AppRoutes.push(context, AppRoutes.bonForm),
                ),
                const SizedBox(height: 12),
                QuickActionTile(
                  label: 'Lihat Keuangan',
                  subtitle: 'Pantau pemasukan, pengeluaran, hutang, dan export PDF',
                  icon: Icons.account_balance_wallet_rounded,
                  onTap: () => AppRoutes.push(context, AppRoutes.finance),
                ),
                const SizedBox(height: 12),
                QuickActionTile(
                  label: 'Kelola Pelanggan',
                  subtitle: 'Lihat daftar pelanggan dan data kontak',
                  icon: Icons.people_alt_rounded,
                  onTap: () =>
                      AppRoutes.push(context, AppRoutes.shell, arguments: 3),
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Transaksi terbaru',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          AppRoutes.push(context, AppRoutes.shell, arguments: 1),
                      child: const Text('Lihat semua'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (provider.recentTransactions.isEmpty)
                  const EmptyState(
                    icon: Icons.receipt_long_rounded,
                    title: 'Belum ada transaksi',
                    subtitle:
                        'Buat invoice atau bon pertama Anda untuk mulai mencatat.',
                  )
                else
                  Card(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        provider.recentTransactions.length * 2 - 1,
                        (index) {
                          if (index.isOdd) {
                            return const Divider(height: 1);
                          }

                          final item =
                              provider.recentTransactions[index ~/ 2];
                          final isInvoice = item['type'] == 'Invoice';
                          return ListTile(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              AppRoutes.push(
                                context,
                                isInvoice
                                    ? AppRoutes.invoiceDetail
                                    : AppRoutes.bonDetail,
                                arguments: item['id'],
                              );
                            },
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                isInvoice
                                    ? Icons.receipt_long_rounded
                                    : Icons.note_alt_rounded,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            title: Text(
                              item['title'] as String,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(
                              '${item['subtitle']} • ${AppFormatters.date(item['date'] as DateTime)}',
                            ),
                            trailing: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  AppFormatters.currency(item['amount'] as num),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 4),
                                StatusBadge(status: item['status']),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Tutorial overlay (shown on top of everything)
        if (_showTutorial)
          TutorialOverlay(onDone: _onTutorialDone),
      ],
    );
  }
}
