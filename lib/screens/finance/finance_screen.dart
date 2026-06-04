import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/financial_entry.dart';
import '../../providers/app_data_provider.dart';
import '../../services/finance_pdf_service.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/summary_card.dart';

enum TimeFilter {
  all('Semua Waktu'),
  today('Hari Ini'),
  week('Minggu Ini'),
  month('Bulan Ini');

  final String label;
  const TimeFilter(this.label);
}

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  FinancialEntryType? _selectedFilter;
  TimeFilter _selectedTimeFilter = TimeFilter.all;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppDataProvider>();
    final summary = provider.financialSummary;
    var entries = provider.combinedFinancialEntries;

    if (_selectedFilter != null) {
      entries = entries.where((e) => e.type == _selectedFilter).toList();
    }

    final now = DateTime.now();
    switch (_selectedTimeFilter) {
      case TimeFilter.all:
        break;
      case TimeFilter.today:
        entries = entries.where((e) => e.date.year == now.year && e.date.month == now.month && e.date.day == now.day).toList();
        break;
      case TimeFilter.week:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final startOfWeekDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        entries = entries.where((e) => !e.date.isBefore(startOfWeekDate)).toList();
        break;
      case TimeFilter.month:
        entries = entries.where((e) => e.date.year == now.year && e.date.month == now.month).toList();
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Keuangan'),
        actions: [
          IconButton.filledTonal(
            tooltip: 'Export PDF keuangan',
            onPressed: () async {
              try {
                await FinancePdfService.exportFinancialReport(provider);
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Gagal export PDF. Jalankan pub get lalu coba lagi.'),
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.picture_as_pdf_rounded),
          ),
          const SizedBox(width: 12),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_finance',
        onPressed: () => _showFinanceForm(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Catat Keuangan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          AppSpacing.screenPadding,
          AppSpacing.screenPadding,
          100,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0EA5E9),
                    Color(0xFF3867F4),
                    Color(0xFF7C4DFF),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Saldo otomatis',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    AppFormatters.currency(summary.balance),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontSize: 32,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pemasukan - pengeluaran. Proyeksi setelah hutang/piutang tertagih: ${AppFormatters.currency(summary.projectedBalance)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.86),
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.08,
              children: [
                SummaryCard(
                  title: 'Pemasukan',
                  value: AppFormatters.currency(summary.income),
                  icon: Icons.trending_up_rounded,
                ),
                SummaryCard(
                  title: 'Pengeluaran',
                  value: AppFormatters.currency(summary.expense),
                  icon: Icons.trending_down_rounded,
                ),
                SummaryCard(
                  title: 'Piutang Customer',
                  value: AppFormatters.currency(summary.receivable),
                  icon: Icons.account_balance_wallet_rounded,
                ),
                SummaryCard(
                  title: 'Hutang Toko',
                  value: AppFormatters.currency(summary.payable),
                  icon: Icons.money_off_rounded,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Visualisasi keuangan',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            FinanceBarChart(summary: summary),
            const SizedBox(height: 20),
            _CalculatorCard(summary: summary),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Gabungan pemasukan, pengeluaran, dan hutang',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: TimeFilter.values.map((filter) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(filter.label),
                      selected: _selectedTimeFilter == filter,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedTimeFilter = filter);
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('Semua'),
                    selected: _selectedFilter == null,
                    onSelected: (selected) {
                      setState(() => _selectedFilter = null);
                    },
                  ),
                  const SizedBox(width: 8),
                  ...FinancialEntryType.values.map((type) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(type.label),
                        selected: _selectedFilter == type,
                        onSelected: (selected) {
                          setState(() {
                            _selectedFilter = selected ? type : null;
                          });
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (entries.isEmpty)
              const EmptyState(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Belum ada data keuangan',
                subtitle: 'Tambahkan catatan pemasukan, pengeluaran, atau hutang.',
              )
            else
              Card(
                child: Column(
                  children: List.generate(entries.length * 2 - 1, (index) {
                    if (index.isOdd) return const Divider(height: 1);
                    final entry = entries[index ~/ 2];
                    return _FinancialEntryTile(entry: entry);
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showFinanceForm(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _FinanceFormSheet(),
    );
  }
}

class FinanceBarChart extends StatelessWidget {
  final FinancialSummary summary;

  const FinanceBarChart({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final values = [summary.income, summary.expense, summary.receivable, summary.payable];
    final maxValue = values.fold<double>(0, (max, value) => value > max ? value : max);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: _BarItem(
                label: 'Masuk',
                value: summary.income,
                maxValue: maxValue,
                icon: Icons.arrow_downward_rounded,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _BarItem(
                label: 'Keluar',
                value: summary.expense,
                maxValue: maxValue,
                icon: Icons.arrow_upward_rounded,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _BarItem(
                label: 'Piutang',
                value: summary.receivable,
                maxValue: maxValue,
                icon: Icons.account_balance_wallet_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _BarItem(
                label: 'Hutang',
                value: summary.payable,
                maxValue: maxValue,
                icon: Icons.money_off_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarItem extends StatelessWidget {
  final String label;
  final double value;
  final double maxValue;
  final IconData icon;

  const _BarItem({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final heightFactor = maxValue <= 0 ? 0.08 : (value / maxValue).clamp(0.08, 1.0).toDouble();

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          AppFormatters.currency(value),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 142,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: heightFactor,
              widthFactor: 1,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      color.withValues(alpha: 0.92),
                      color.withValues(alpha: 0.18),
                    ],
                  ),
                ),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Icon(icon, size: 18, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _CalculatorCard extends StatelessWidget {
  final FinancialSummary summary;

  const _CalculatorCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.calculate_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Kalkulator otomatis',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _FormulaRow(
              label: 'Saldo kas',
              formula: 'pemasukan - pengeluaran',
              value: AppFormatters.currency(summary.balance),
            ),
            const Divider(height: 24),
            _FormulaRow(
              label: 'Piutang tertagih',
              formula: 'invoice/bon belum lunas',
              value: AppFormatters.currency(summary.receivable),
            ),
            const Divider(height: 24),
            _FormulaRow(
              label: 'Kewajiban hutang toko',
              formula: 'hutang usaha belum lunas',
              value: AppFormatters.currency(summary.payable),
            ),
            const Divider(height: 24),
            _FormulaRow(
              label: 'Proyeksi total',
              formula: 'saldo kas + piutang - kewajiban',
              value: AppFormatters.currency(summary.projectedBalance),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormulaRow extends StatelessWidget {
  final String label;
  final String formula;
  final String value;

  const _FormulaRow({
    required this.label,
    required this.formula,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(
                formula,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _FinancialEntryTile extends StatelessWidget {
  final FinancialEntry entry;

  const _FinancialEntryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final icon = switch (entry.type) {
      FinancialEntryType.income => Icons.south_west_rounded,
      FinancialEntryType.expense => Icons.north_east_rounded,
      FinancialEntryType.payable => Icons.money_off_rounded,
      FinancialEntryType.receivable => Icons.account_balance_wallet_rounded,
    };

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, color: colorScheme.primary),
      ),
      title: Text(
        entry.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        '${entry.type.label} • ${entry.sourceLabel} • ${AppFormatters.date(entry.date)}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AppFormatters.currency(entry.amount),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              if (entry.isAutoGenerated)
                const Text(
                  'Auto',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
            ],
          ),
          if (!entry.isAutoGenerated) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
              onPressed: () async {
                final shouldDelete = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Hapus Catatan'),
                        content: const Text('Yakin ingin menghapus catatan manual ini?'),
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

                context.read<AppDataProvider>().deleteFinancialEntry(entry.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Catatan berhasil dihapus')),
                );
              },
            ),
          ]
        ],
      ),
    );
  }
}

class _FinanceFormSheet extends StatefulWidget {
  const _FinanceFormSheet();

  @override
  State<_FinanceFormSheet> createState() => _FinanceFormSheetState();
}

class _FinanceFormSheetState extends State<_FinanceFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  FinancialEntryType _type = FinancialEntryType.income;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(18, 18, 18, bottomInset + 18),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD7DFEE),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Tambah catatan keuangan',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                'Catat pemasukan, pengeluaran, atau hutang. Saldo akan dihitung otomatis.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              DropdownButtonFormField<FinancialEntryType>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Jenis catatan'),
                items: FinancialEntryType.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _type = value);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Judul', hintText: 'Contoh: Bayar Listrik / Gaji Karyawan',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Judul wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Nominal', hintText: 'Contoh: 100000',
                ),
                validator: (value) {
                  final amount = _parseAmount(value ?? '');
                  if (amount <= 0) return 'Nominal harus lebih dari 0';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Catatan', hintText: 'Contoh: Pembayaran tempo 14 hari',
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('Simpan dan hitung otomatis'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<AppDataProvider>();
    provider.addFinancialEntry(
      FinancialEntry(
        id: provider.generateFinancialEntryId(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        amount: _parseAmount(_amountController.text),
        date: DateTime.now(),
        type: _type,
      ),
    );

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Catatan keuangan berhasil ditambahkan')),
    );
  }

  double _parseAmount(String value) {
    final normalized = value.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(normalized) ?? 0;
  }
}
