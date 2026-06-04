import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/hutang.dart';
import '../../models/product_item.dart';
import '../../models/transaction_status.dart';
import '../../providers/app_data_provider.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';

class HutangFormScreen extends StatefulWidget {
  final Hutang? hutang;

  const HutangFormScreen({super.key, this.hutang});

  @override
  State<HutangFormScreen> createState() => _HutangFormScreenState();
}

class _HutangFormScreenState extends State<HutangFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  String? _selectedCustomerId;
  late DateTime _selectedDate;
  final List<_HutangLineDraft> _lines = [];

  bool get isEdit => widget.hutang != null;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.hutang?.date ?? DateTime.now();
    _selectedCustomerId = widget.hutang?.customerId;
    _notesController.text = widget.hutang?.notes ?? '';

    if (widget.hutang != null) {
      for (final line in widget.hutang!.items) {
        _lines.add(
          _HutangLineDraft(
            productName: line.itemName,
            qtyController: TextEditingController(text: line.qty.toString()),
            priceController: TextEditingController(text: line.price.toStringAsFixed(0)),
          ),
        );
      }
    }

    if (_lines.isEmpty) {
      _lines.add(_HutangLineDraft.empty());
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  double _lineSubtotal(_HutangLineDraft line) {
    final qty = int.tryParse(line.qtyController.text) ?? 0;
    final price = double.tryParse(line.priceController.text) ?? 0;
    return qty * price;
  }

  double get _total => _lines.fold(0, (sum, line) => sum + _lineSubtotal(line));

  void _addLine() {
    setState(() {
      _lines.add(_HutangLineDraft.empty());
    });
  }

  void _removeLine(int index) {
    if (_lines.length == 1) return;
    setState(() {
      _lines[index].dispose();
      _lines.removeAt(index);
    });
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (selected != null) {
      setState(() => _selectedDate = selected);
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomerId == null || _selectedCustomerId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih pelanggan terlebih dahulu')),
      );
      return;
    }

    final provider = context.read<AppDataProvider>();
    final customer = provider.findCustomerById(_selectedCustomerId!);
    if (customer == null) return;

    final items = <HutangLine>[];
    for (var i = 0; i < _lines.length; i++) {
      final line = _lines[i];
      final qty = int.tryParse(line.qtyController.text) ?? 0;
      final price = double.tryParse(line.priceController.text) ?? 0;
      if (line.productName == null || line.productName!.isEmpty || qty <= 0 || price <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lengkapi semua Barang Hutang dengan benar')),
        );
        return;
      }

      items.add(
        HutangLine(
          id: isEdit && i < (widget.hutang?.items.length ?? 0)
              ? widget.hutang!.items[i].id
              : provider.generateLineId(i),
          itemName: line.productName!,
          qty: qty,
          price: price,
        ),
      );
    }

    final newHutang = Hutang(
      id: widget.hutang?.id ?? provider.generateHutangId(),
      number: widget.hutang?.number ?? provider.generateHutangNumber(),
      customerId: customer.id,
      customerName: customer.name,
      date: _selectedDate,
      items: items,
      notes: _notesController.text.trim(),
      status: widget.hutang?.status ?? TransactionStatus.unpaid,
    );

    if (isEdit) {
      provider.updateHutang(newHutang);
    } else {
      provider.addHutang(newHutang);
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(isEdit ? 'Hutang berhasil diperbarui' : 'Hutang berhasil ditambahkan')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppDataProvider>();
    final customers = provider.customers;
    final products = provider.products;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Hutang' : 'Buat Hutang')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCustomerId,
                        items: customers
                            .map(
                              (customer) => DropdownMenuItem(
                                value: customer.id,
                                child: Text(customer.name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() => _selectedCustomerId = value);
                        },
                        decoration: const InputDecoration(labelText: 'Pilih pelanggan', hintText: 'Contoh: Budi Santoso'),
                      ),
                      const SizedBox(height: 14),
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(14),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Tanggal Hutang', hintText: 'Pilih tanggal',
                            suffixIcon: Icon(Icons.calendar_today_outlined),
                          ),
                          child: Text(AppFormatters.date(_selectedDate)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: 'Catatan', hintText: 'Contoh: Pembayaran tempo 14 hari'),
                      ),
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Status default: Unpaid',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Barang Hutang',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addLine,
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah Barang'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...List.generate(
                _lines.length,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _HutangLineCard(
                    line: _lines[index],
                    products: products,
                    onChanged: () => setState(() {}),
                    onDelete: () => _removeLine(index),
                    subtotal: _lineSubtotal(_lines[index]),
                    canDelete: _lines.length > 1,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Total',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        AppFormatters.currency(_total),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Text('Simpan Hutang'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HutangLineCard extends StatelessWidget {
  final _HutangLineDraft line;
  final List<ProductItem> products;
  final VoidCallback onChanged;
  final VoidCallback onDelete;
  final bool canDelete;
  final double subtotal;

  const _HutangLineCard({
    required this.line,
    required this.products,
    required this.onChanged,
    required this.onDelete,
    required this.canDelete,
    required this.subtotal,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: line.productName,
              decoration: const InputDecoration(labelText: 'Pilih stok/barang', hintText: 'Contoh: Beras Premium 5kg'),
              items: products
                  .map(
                    (product) => DropdownMenuItem<String>(
                      value: product.name,
                      child: Text(product.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                line.productName = value;
                ProductItem? selected;
                for (final product in products) {
                  if (product.name == value) {
                    selected = product;
                    break;
                  }
                }
                if (selected != null) {
                  line.priceController.text = selected.price.toStringAsFixed(0);
                }
                onChanged();
              },
              validator: (value) => value == null || value.isEmpty ? 'Pilih stok/barang' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: line.qtyController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Qty', hintText: 'Contoh: 1'),
                    onChanged: (_) => onChanged(),
                    validator: (value) {
                      final qty = int.tryParse(value ?? '');
                      if (qty == null || qty <= 0) return 'Qty';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: line.priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Harga', hintText: 'Contoh: 50000'),
                    onChanged: (_) => onChanged(),
                    validator: (value) {
                      final price = double.tryParse(value ?? '');
                      if (price == null || price <= 0) return 'Harga';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Subtotal: ${AppFormatters.currency(subtotal)}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  onPressed: canDelete ? onDelete : null,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HutangLineDraft {
  String? productName;
  final TextEditingController qtyController;
  final TextEditingController priceController;

  _HutangLineDraft({
    required this.productName,
    required this.qtyController,
    required this.priceController,
  });

  factory _HutangLineDraft.empty() {
    return _HutangLineDraft(
      productName: null,
      qtyController: TextEditingController(text: '1'),
      priceController: TextEditingController(),
    );
  }

  void dispose() {
    qtyController.dispose();
    priceController.dispose();
  }
}
