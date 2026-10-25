class MoneyBudget {
  const MoneyBudget({required this.category, required this.amountCents});

  final String category;
  final int amountCents;

  factory MoneyBudget.fromMap(Map<String, Object?> map) => MoneyBudget(
        category: map['category'] as String,
        amountCents: map['amount_cents'] as int,
      );
}
