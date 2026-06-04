import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../models/product_item.dart';
import '../../providers/app_data_provider.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/search_bar_field.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final products = context.watch<AppDataProvider>().products;
    final filtered = products.where((product) {
      final query = _search.toLowerCase();
      return product.name.toLowerCase().contains(query) ||
          (product.category ?? '').toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Stok / Barang')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          children: [
            SearchBarField(
              hintText: 'Cari stok atau barang',
              onChanged: (value) => setState(() => _search = value),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: filtered.isEmpty
                  ? const EmptyState(
                      title: 'Belum ada stok/barang',
                      subtitle:
                          'Tambahkan daftar stok atau barang untuk mempermudah pembuatan invoice.',
                      icon: Icons.inventory_2_outlined,
                    )
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final product = filtered[index];
                        return _ProductCard(product: product);
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_product',
        onPressed: () => AppRoutes.push(context, AppRoutes.productForm),
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductItem product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: () => AppRoutes.push(context, AppRoutes.productDetail, arguments: product),
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(
            Icons.inventory_2_rounded,
            color: AppColors.primary,
          ),
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (product.category != null && product.category!.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    product.category!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                AppFormatters.currency(product.price),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
        ),
        trailing: IconButton(
          onPressed: () => AppRoutes.push(
            context,
            AppRoutes.productForm,
            arguments: product,
          ),
          icon: const Icon(Icons.edit_outlined),
        ),
      ),
    );
  }
}
