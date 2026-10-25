enum MoneyType { income, expense }

extension MoneyTypeLabel on MoneyType {
  String get label => this == MoneyType.income ? 'Income' : 'Expense';
}

class MoneyTransaction {
  const MoneyTransaction({
    this.id,
    required this.type,
    required this.amountCents,
    required this.category,
    required this.date,
    this.note = '',
  });

  final int? id;
  final MoneyType type;
  final int amountCents;
  final String category;
  final DateTime date;
  final String note;

  Map<String, Object?> toMap() => {
        'id': id,
        'type': type.name,
        'amount_cents': amountCents,
        'category': category,
        'date': date.toIso8601String(),
        'note': note,
      };

  factory MoneyTransaction.fromMap(Map<String, Object?> map) => MoneyTransaction(
        id: map['id'] as int?,
        type: MoneyType.values.byName(map['type'] as String),
        amountCents: map['amount_cents'] as int,
        category: map['category'] as String,
        date: DateTime.parse(map['date'] as String),
        note: (map['note'] as String?) ?? '',
      );
}
