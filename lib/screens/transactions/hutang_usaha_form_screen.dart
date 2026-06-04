import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/hutang_usaha.dart';
import '../../models/transaction_status.dart';
import '../../providers/app_data_provider.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';

class HutangUsahaFormScreen extends StatefulWidget {
  final HutangUsaha? hutangUsaha;

  const HutangUsahaFormScreen({super.key, this.hutangUsaha});

  @override
  State<HutangUsahaFormScreen> createState() => _HutangUsahaFormScreenState();
}

class _HutangUsahaFormScreenState extends State<HutangUsahaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _supplierNameController;
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;
  late DateTime _selectedDate;
  late TransactionStatus _status;

  bool get isEdit => widget.hutangUsaha != null;

  @override
  void initState() {
    super.initState();
    _supplierNameController = TextEditingController(text: widget.hutangUsaha?.supplierName ?? '');
    _amountController = TextEditingController(
      text: widget.hutangUsaha != null ? widget.hutangUsaha!.amount.toStringAsFixed(0) : '',
    );
    _notesController = TextEditingController(text: widget.hutangUsaha?.notes ?? '');
    _selectedDate = widget.hutangUsaha?.date ?? DateTime.now();
    _status = widget.hutangUsaha?.status ?? TransactionStatus.unpaid;
  }

  @override
  void dispose() {
    _supplierNameController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
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

    final provider = context.read<AppDataProvider>();
    final hutangUsaha = HutangUsaha(
      id: widget.hutangUsaha?.id ?? provider.generateHutangUsahaId(),
      number: widget.hutangUsaha?.number ?? provider.generateHutangUsahaNumber(),
      supplierName: _supplierNameController.text.trim(),
      amount: double.parse(_amountController.text.trim()),
      date: _selectedDate,
      notes: _notesController.text.trim(),
      status: _status,
    );

    if (isEdit) {
      provider.updateHutangUsaha(hutangUsaha);
    } else {
      provider.addHutangUsaha(hutangUsaha);
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(isEdit ? 'Hutang Usaha berhasil diperbarui' : 'Hutang Usaha berhasil ditambahkan')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Hutang Usaha' : 'Buat Hutang Usaha')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _supplierNameController,
                        decoration: const InputDecoration(labelText: 'Nama Suplier/Penagih', hintText: 'Contoh: PT. ABC'),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Nama Suplier/Penagih wajib diisi' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Nominal', hintText: 'Contoh: 100000'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nominal wajib diisi';
                          }
                          final parsed = double.tryParse(value.trim());
                          if (parsed == null || parsed <= 0) {
                            return 'Nominal tidak valid';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
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
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Text('Simpan Hutang Usaha'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
