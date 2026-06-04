import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/bon.dart';
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

  bool get isEdit => widget.bon != null;

  @override
  void initState() {
    super.initState();
    _customerNameController = TextEditingController(text: widget.bon?.customerName ?? '');
    _amountController = TextEditingController(
      text: widget.bon != null ? widget.bon!.amount.toStringAsFixed(0) : '',
    );
    _notesController = TextEditingController(text: widget.bon?.notes ?? '');
    _selectedDate = widget.bon?.date ?? DateTime.now();
    _status = widget.bon?.status ?? TransactionStatus.unpaid;
  }

  @override
  void dispose() {
    _customerNameController.dispose();
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
    final bon = Bon(
      id: widget.bon?.id ?? provider.generateBonId(),
      customerName: _customerNameController.text.trim(),
      amount: double.parse(_amountController.text.trim()),
      date: _selectedDate,
      notes: _notesController.text.trim(),
      status: _status,
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
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Bon' : 'Buat Bon')),
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
                        controller: _customerNameController,
                        decoration: const InputDecoration(labelText: 'Nama pelanggan', hintText: 'Contoh: Budi Santoso'),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Nama pelanggan wajib diisi' : null,
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
