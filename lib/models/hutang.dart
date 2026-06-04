import 'transaction_status.dart';

class HutangLine {
  final String id;
  final String itemName;
  final int qty;
  final double price;

  HutangLine({
    required this.id,
    required this.itemName,
    required this.qty,
    required this.price,
  });

  double get subtotal => qty * price;

  HutangLine copyWith({
    String? id,
    String? itemName,
    int? qty,
    double? price,
  }) {
    return HutangLine(
      id: id ?? this.id,
      itemName: itemName ?? this.itemName,
      qty: qty ?? this.qty,
      price: price ?? this.price,
    );
  }
}

class Hutang {
  final String id;
  final String number;
  final String customerId;
  final String customerName;
  final DateTime date;
  final List<HutangLine> items;
  final String notes;
  final TransactionStatus status;

  Hutang({
    required this.id,
    required this.number,
    required this.customerId,
    required this.customerName,
    required this.date,
    required this.items,
    required this.notes,
    required this.status,
  });

  double get total => items.fold(0, (sum, item) => sum + item.subtotal);

  Hutang copyWith({
    String? id,
    String? number,
    String? customerId,
    String? customerName,
    DateTime? date,
    List<HutangLine>? items,
    String? notes,
    TransactionStatus? status,
  }) {
    return Hutang(
      id: id ?? this.id,
      number: number ?? this.number,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      date: date ?? this.date,
      items: items ?? this.items,
      notes: notes ?? this.notes,
      status: status ?? this.status,
    );
  }
}
