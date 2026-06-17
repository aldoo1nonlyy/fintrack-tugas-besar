import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/bon.dart';
import '../../models/product_item.dart';
import '../../models/transaction_status.dart';
import '../../providers/app_data_provider.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';

class BonFormScreen extends StatefulWidget {
  final Bon? bon;

  const BonFormScreen({super.key, this.bon});

  @override
  State<BonFormScreen> createState() => _BonFormScreenState();
}

class _BonFormScreenState extends State<BonFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _customerNameController;
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;
  late DateTime _selectedDate;
  late TransactionStatus _status;
  final List<_BonLineDraft> _lines = [];

  bool get isEdit => widget.bon != null;

  @override
  void initState() {
    super.initState();
    _customerNameController = TextEditingController(text: widget.bon?.customerName ?? '');
    _amountController = TextEditingController(
      text: widget.bon != null ? (widget.bon!.items.isEmpty ? widget.bon!.amount.toStringAsFixed(0) : '') : '',
    );
    _notesController = TextEditingController(text: widget.bon?.notes ?? '');
    _selectedDate = widget.bon?.date ?? DateTime.now();
    _status = widget.bon?.status ?? TransactionStatus.unpaid;

    if (widget.bon != null && widget.bon!.items.isNotEmpty) {
      for (final line in widget.bon!.items) {
        _lines.add(
          _BonLineDraft(
            productName: line.itemName,
            qtyController: TextEditingController(text: line.qty.toString()),
            priceController: TextEditingController(text: line.price.toStringAsFixed(0)),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  double _lineSubtotal(_BonLineDraft line) {
    final qty = int.tryParse(line.qtyController.text) ?? 0;
    final price = double.tryParse(line.priceController.text) ?? 0;
    return qty * price;
  }

  double get _itemsTotal => _lines.fold(0, (sum, line) => sum + _lineSubtotal(line));
  double get _finalTotal => _lines.isEmpty ? (double.tryParse(_amountController.text) ?? 0) : _itemsTotal;

  void _addLine() {
    setState(() {
      _lines.add(_BonLineDraft.empty());
      _amountController.clear(); // Clear manual amount when items are added
    });
  }

  void _removeLine(int index) {
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
    
    if (_lines.isEmpty && (double.tryParse(_amountController.text) ?? 0) <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Masukkan nominal bon atau tambahkan setidaknya satu barang')),
        );
        return;
    }

    final provider = context.read<AppDataProvider>();
    final items = <BonLine>[];
    
    for (var i = 0; i < _lines.length; i++) {
      final line = _lines[i];
      final qty = int.tryParse(line.qtyController.text) ?? 0;
      final price = double.tryParse(line.priceController.text) ?? 0;
      if (line.productName == null || line.productName!.isEmpty || qty <= 0 || price <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lengkapi semua Barang Bon dengan benar')),
        );
        return;
      }

      items.add(
        BonLine(
          id: isEdit && i < (widget.bon?.items.length ?? 0)
              ? widget.bon!.items[i].id
              : provider.generateLineId(i),
          itemName: line.productName!,
          qty: qty,
          price: price,
        ),
      );
    }

    final bon = Bon(
      id: widget.bon?.id ?? provider.generateBonId(),
      customerName: _customerNameController.text.trim(),
      amount: _lines.isEmpty ? double.parse(_amountController.text.trim()) : 0, // Ignored if items exist
      date: _selectedDate,
      notes: _notesController.text.trim(),
      status: _status,
      items: items,
    );

    if (isEdit) {
      provider.updateBon(bon);
    } else {
      provider.addBon(bon);
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(isEdit ? 'Bon berhasil diperbarui' : 'Bon berhasil ditambahkan')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = context.watch<AppDataProvider>().products;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Bon' : 'Buat Bon')),
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
                      TextFormField(
                        controller: _customerNameController,
                        decoration: const InputDecoration(labelText: 'Nama pelanggan', hintText: 'Contoh: Budi Santoso'),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Nama pelanggan wajib diisi' : null,
                      ),
                      const SizedBox(height: 14),
                      if (_lines.isEmpty)
                        TextFormField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Nominal', hintText: 'Contoh: 100000'),
                          validator: (value) {
                            if (_lines.isNotEmpty) return null; // Not needed if there are items
                            if (value == null || value.trim().isEmpty) {
                              return 'Nominal wajib diisi jika tidak ada barang';
                            }
                            final parsed = double.tryParse(value.trim());
                            if (parsed == null || parsed <= 0) {
                              return 'Nominal tidak valid';
                            }
                            return null;
                          },
                        ),
                      if (_lines.isEmpty) const SizedBox(height: 14),
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(14),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Tanggal', hintText: 'Pilih tanggal',
                            suffixIcon: Icon(Icons.calendar_today_outlined),
                          ),
                          child: Text(AppFormatters.date(_selectedDate)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<TransactionStatus>(
                        initialValue: _status,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: TransactionStatus.values
                            .map(
                              (status) => DropdownMenuItem(
                                value: status,
                                child: Text(status.label),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _status = value);
                          }
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: 'Catatan', hintText: 'Contoh: Pembayaran tempo 14 hari'),
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
                      'Barang Bon (Opsional)',
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
              if (_lines.isNotEmpty) const SizedBox(height: 8),
              ...List.generate(
                _lines.length,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _BonLineCard(
                    line: _lines[index],
                    products: products,
                    onChanged: () => setState(() {}),
                    onDelete: () => _removeLine(index),
                    subtotal: _lineSubtotal(_lines[index]),
                  ),
                ),
              ),
              if (_lines.isNotEmpty) ...[
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
                          AppFormatters.currency(_finalTotal),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Text('Simpan Bon'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BonLineCard extends StatelessWidget {
  final _BonLineDraft line;
  final List<ProductItem> products;
  final VoidCallback onChanged;
  final VoidCallback onDelete;
  final double subtotal;

  const _BonLineCard({
    required this.line,
    required this.products,
    required this.onChanged,
    required this.onDelete,
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
                  onPressed: onDelete,
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

class _BonLineDraft {
  String? productName;
  final TextEditingController qtyController;
  final TextEditingController priceController;

  _BonLineDraft({
    required this.productName,
    required this.qtyController,
    required this.priceController,
  });

  factory _BonLineDraft.empty() {
    return _BonLineDraft(
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
