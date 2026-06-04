import 'transaction_status.dart';

class InvoiceLine {
  final String id;
  final String itemName;
  final int qty;
  final double price;

  InvoiceLine({
    required this.id,
    required this.itemName,
    required this.qty,
    required this.price,
  });

  double get subtotal => qty * price;

  InvoiceLine copyWith({
    String? id,
    String? itemName,
    int? qty,
    double? price,
  }) {
    return InvoiceLine(
      id: id ?? this.id,
      itemName: itemName ?? this.itemName,
      qty: qty ?? this.qty,
      price: price ?? this.price,
    );
  }
}

class Invoice {
  final String id;
  final String number;
  final String customerId;
  final String customerName;
  final DateTime date;
  final List<InvoiceLine> items;
  final String notes;
  final TransactionStatus status;

  Invoice({
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

  Invoice copyWith({
    String? id,
    String? number,
    String? customerId,
    String? customerName,
    DateTime? date,
    List<InvoiceLine>? items,
    String? notes,
    TransactionStatus? status,
  }) {
    return Invoice(
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
