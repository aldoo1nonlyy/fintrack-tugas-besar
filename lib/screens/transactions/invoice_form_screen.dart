import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/invoice.dart';
import '../../models/product_item.dart';
import '../../models/transaction_status.dart';
import '../../providers/app_data_provider.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';

class InvoiceFormScreen extends StatefulWidget {
  final Invoice? invoice;

  const InvoiceFormScreen({super.key, this.invoice});

  @override
  State<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
}

class _InvoiceFormScreenState extends State<InvoiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  String? _selectedCustomerId;
  late DateTime _selectedDate;
  final List<_InvoiceLineDraft> _lines = [];

  bool get isEdit => widget.invoice != null;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.invoice?.date ?? DateTime.now();
    _selectedCustomerId = widget.invoice?.customerId;
    _notesController.text = widget.invoice?.notes ?? '';

    if (widget.invoice != null) {
      for (final line in widget.invoice!.items) {
        _lines.add(
          _InvoiceLineDraft(
            productName: line.itemName,
            qtyController: TextEditingController(text: line.qty.toString()),
            priceController: TextEditingController(text: line.price.toStringAsFixed(0)),
          ),
        );
      }
    }

    if (_lines.isEmpty) {
      _lines.add(_InvoiceLineDraft.empty());
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

  double _lineSubtotal(_InvoiceLineDraft line) {
    final qty = int.tryParse(line.qtyController.text) ?? 0;
    final price = double.tryParse(line.priceController.text) ?? 0;
    return qty * price;
  }

  double get _total => _lines.fold(0, (sum, line) => sum + _lineSubtotal(line));

  void _addLine() {
    setState(() {
      _lines.add(_InvoiceLineDraft.empty());
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

    final items = <InvoiceLine>[];
    for (var i = 0; i < _lines.length; i++) {
      final line = _lines[i];
      final qty = int.tryParse(line.qtyController.text) ?? 0;
      final price = double.tryParse(line.priceController.text) ?? 0;
      if (line.productName == null || line.productName!.isEmpty || qty <= 0 || price <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lengkapi semua barang invoice dengan benar')),
        );
        return;
      }

      items.add(
        InvoiceLine(
          id: isEdit && i < (widget.invoice?.items.length ?? 0)
              ? widget.invoice!.items[i].id
              : provider.generateLineId(i),
          itemName: line.productName!,
          qty: qty,
          price: price,
        ),
      );
    }

    final invoice = Invoice(
      id: widget.invoice?.id ?? provider.generateInvoiceId(),
      number: widget.invoice?.number ?? provider.generateInvoiceNumber(),
      customerId: customer.id,
      customerName: customer.name,
      date: _selectedDate,
      items: items,
      notes: _notesController.text.trim(),
      status: widget.invoice?.status ?? TransactionStatus.unpaid,
    );

    if (isEdit) {
      provider.updateInvoice(invoice);
    } else {
      provider.addInvoice(invoice);
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(isEdit ? 'Invoice berhasil diperbarui' : 'Invoice berhasil ditambahkan')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppDataProvider>();
    final customers = provider.customers;
    final products = provider.products;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Invoice' : 'Buat Invoice')),
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
                            labelText: 'Tanggal invoice', hintText: 'Pilih tanggal',
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
                      'Daftar Barang',
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
                  child: _InvoiceLineCard(
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
                  child: const Text('Simpan Invoice'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InvoiceLineCard extends StatelessWidget {
  final _InvoiceLineDraft line;
  final List<ProductItem> products;
  final VoidCallback onChanged;
  final VoidCallback onDelete;
  final bool canDelete;
  final double subtotal;

  const _InvoiceLineCard({
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

class _InvoiceLineDraft {
  String? productName;
  final TextEditingController qtyController;
  final TextEditingController priceController;

  _InvoiceLineDraft({
    required this.productName,
    required this.qtyController,
    required this.priceController,
  });

  factory _InvoiceLineDraft.empty() {
    return _InvoiceLineDraft(
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
