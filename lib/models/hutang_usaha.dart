import 'transaction_status.dart';

class HutangUsaha {
  final String id;
  final String number;
  final String supplierName;
  final double amount;
  final DateTime date;
  final String notes;
  final TransactionStatus status;

  HutangUsaha({
    required this.id,
    required this.number,
    required this.supplierName,
    required this.amount,
    required this.date,
    this.notes = '',
    this.status = TransactionStatus.unpaid,
  });

  HutangUsaha copyWith({
    String? id,
    String? number,
    String? supplierName,
    double? amount,
    DateTime? date,
    String? notes,
    TransactionStatus? status,
  }) {
    return HutangUsaha(
      id: id ?? this.id,
      number: number ?? this.number,
      supplierName: supplierName ?? this.supplierName,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      status: status ?? this.status,
    );
  }
}
