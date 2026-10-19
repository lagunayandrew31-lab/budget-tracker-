class TransactionEntry {
  final int? id;
  final String type;
  final double amount;
  final String category;
  final DateTime date;
  final String paymentMethod;
  final String notes;
  final bool recurring;

  const TransactionEntry({
    this.id,
    required this.type,
    required this.amount,
    required this.category,
    required this.date,
    required this.paymentMethod,
    this.notes = '',
    this.recurring = false,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'type': type,
        'amount': amount,
        'category': category,
        'date': date.toIso8601String(),
        'payment_method': paymentMethod,
        'notes': notes,
        'recurring': recurring ? 1 : 0,
      };

  factory TransactionEntry.fromMap(Map<String, Object?> map) =>
      TransactionEntry(
        id: map['id'] as int?,
        type: map['type'] as String,
        amount: (map['amount'] as num).toDouble(),
        category: map['category'] as String,
        date: DateTime.parse(map['date'] as String),
        paymentMethod: map['payment_method'] as String,
        notes: (map['notes'] as String?) ?? '',
        recurring: (map['recurring'] as int? ?? 0) == 1,
      );
}
