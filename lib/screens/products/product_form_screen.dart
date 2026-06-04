import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product_item.dart';
import '../../providers/app_data_provider.dart';
import '../../utils/constants.dart';

class ProductFormScreen extends StatefulWidget {
  final ProductItem? product;

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _categoryController;

  bool get isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _priceController = TextEditingController(
      text: widget.product != null
          ? widget.product!.price.toStringAsFixed(0)
          : '',
    );
    _categoryController =
        TextEditingController(text: widget.product?.category ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final provider = context.read<AppDataProvider>();
    final product = ProductItem(
      id: widget.product?.id ?? provider.generateProductId(),
      name: _nameController.text.trim(),
      price: double.parse(_priceController.text.trim()),
      category: _categoryController.text.trim().isEmpty
          ? null
          : _categoryController.text.trim(),
    );

    if (isEdit) {
      provider.updateProduct(product);
    } else {
      provider.addProduct(product);
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isEdit
              ? 'Stok/barang berhasil diperbarui'
              : 'Stok/barang berhasil ditambahkan',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Stok/barang' : 'Tambah Stok/barang')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Informasi item',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Masukkan nama item, harga, dan kategori untuk mempermudah penyusunan invoice.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _nameController,
                        decoration:
                            const InputDecoration(labelText: 'Nama Stok/barang', hintText: 'Contoh: Minyak Goreng 2L'),
                        validator: (value) => value == null || value.trim().isEmpty
                            ? 'Nama wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _priceController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Harga', hintText: 'Contoh: 50000'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Harga wajib diisi';
                          }
                          final parsed = double.tryParse(value.trim());
                          if (parsed == null || parsed <= 0) {
                            return 'Harga tidak valid';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _categoryController,
                        decoration:
                            const InputDecoration(labelText: 'Kategori (opsional)', hintText: 'Contoh: Sembako'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: Text(isEdit ? 'Simpan Perubahan' : 'Simpan Stok/barang'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
