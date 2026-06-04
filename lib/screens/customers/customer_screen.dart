import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../models/customer.dart';
import '../../providers/app_data_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/search_bar_field.dart';

class CustomerScreen extends StatefulWidget {
  const CustomerScreen({super.key});

  @override
  State<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final customers = context.watch<AppDataProvider>().customers;
    final filtered = customers.where((customer) {
      final query = _search.toLowerCase();
      return customer.name.toLowerCase().contains(query) ||
          customer.phone.toLowerCase().contains(query) ||
          customer.address.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Pelanggan')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          children: [
            SearchBarField(
              hintText: 'Cari pelanggan',
              onChanged: (value) => setState(() => _search = value),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: filtered.isEmpty
                  ? const EmptyState(
                      title: 'Belum ada pelanggan',
                      subtitle:
                          'Tambahkan pelanggan baru untuk mulai membuat transaksi.',
                      icon: Icons.people_outline,
                    )
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final customer = filtered[index];
                        return _CustomerCard(customer: customer);
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_customer',
        onPressed: () => AppRoutes.push(context, AppRoutes.customerForm),
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final Customer customer;

  const _CustomerCard({required this.customer});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: () => AppRoutes.push(context, AppRoutes.customerDetail, arguments: customer),
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF3867F4), Color(0xFF6A5AF9)],
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Center(
            child: Text(
              customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ),
        ),
        title: Text(
          customer.name,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MetaText(icon: Icons.call_outlined, text: customer.phone),
              const SizedBox(height: 6),
              _MetaText(icon: Icons.location_on_outlined, text: customer.address),
              if (customer.email != null && customer.email!.isNotEmpty) ...[
                const SizedBox(height: 6),
                _MetaText(icon: Icons.email_outlined, text: customer.email!),
              ],
            ],
          ),
        ),
        trailing: IconButton(
          onPressed: () => AppRoutes.push(
            context,
            AppRoutes.customerForm,
            arguments: customer,
          ),
          icon: const Icon(Icons.edit_outlined),
        ),
      ),
    );
  }
}

class _MetaText extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaText({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.mutedText),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
