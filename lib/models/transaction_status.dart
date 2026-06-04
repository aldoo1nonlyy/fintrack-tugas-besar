enum TransactionStatus {
  unpaid,
  paid,
  overdue,
}

extension TransactionStatusX on TransactionStatus {
  String get label {
    switch (this) {
      case TransactionStatus.unpaid:
        return 'Unpaid';
      case TransactionStatus.paid:
        return 'Lunas';
      case TransactionStatus.overdue:
        return 'Overdue';
    }
  }
}
