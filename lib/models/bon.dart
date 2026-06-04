import 'transaction_status.dart';

class Bon {
  final String id;
  final String customerName;
  final double amount;
  final DateTime date;
  final String notes;
  final TransactionStatus status;

  Bon({
    required this.id,
    required this.customerName,
    required this.amount,
    required this.date,
    required this.notes,
    required this.status,
  });

  Bon copyWith({
    String? id,
    String? customerName,
    double? amount,
    DateTime? date,
    String? notes,
    TransactionStatus? status,
  }) {
    return Bon(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      status: status ?? this.status,
    );
  }
}
