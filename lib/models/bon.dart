import 'transaction_status.dart';

class BonLine {
  final String id;
  final String itemName;
  final int qty;
  final double price;

  BonLine({
    required this.id,
    required this.itemName,
    required this.qty,
    required this.price,
  });

  double get subtotal => qty * price;

  BonLine copyWith({
    String? id,
    String? itemName,
    int? qty,
    double? price,
  }) {
    return BonLine(
      id: id ?? this.id,
      itemName: itemName ?? this.itemName,
      qty: qty ?? this.qty,
      price: price ?? this.price,
    );
  }
}

class Bon {
  final String id;
  final String customerName;
  final double _amount; // Private field to hold explicit amount if items are empty
  final DateTime date;
  final String notes;
  final TransactionStatus status;
  final List<BonLine> items;

  Bon({
    required this.id,
    required this.customerName,
    required double amount,
    required this.date,
    required this.notes,
    required this.status,
    this.items = const [],
  }) : _amount = amount;

  // Calculates total based on items if present, otherwise returns explicit amount
  double get amount => items.isEmpty ? _amount : items.fold(0, (sum, item) => sum + item.subtotal);

  Bon copyWith({
    String? id,
    String? customerName,
    double? amount,
    DateTime? date,
    String? notes,
    TransactionStatus? status,
    List<BonLine>? items,
  }) {
    return Bon(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      amount: amount ?? _amount,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      items: items ?? this.items,
    );
  }
}
