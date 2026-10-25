import 'package:flutter/material.dart';

import '../models/money_transaction.dart';

const brandBlue = Color(0xFF1769E0);
const deepBlue = Color(0xFF0E47A1);
const paleBlue = Color(0xFFEAF2FF);
const backgroundColor = Color(0xFFF5F8FE);
const greenColor = Color(0xFF16A06A);
const redColor = Color(0xFFE45460);

const expenseCategories = <String>[
  'Food', 'Transport', 'Shopping', 'Bills', 'Health', 'Education',
  'Entertainment', 'Housing', 'Other',
];
const incomeCategories = <String>[
  'Salary', 'Business', 'Freelance', 'Gift', 'Investment', 'Other',
];

const monthNames = <String>[
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];
const shortMonths = <String>[
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String formatMoney(int cents, {bool compact = false}) {
  final negative = cents < 0;
  final amount = cents.abs();
  final whole = amount ~/ 100;
  final decimal = amount % 100;
  final number = whole.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (_) => ',',
      );
  final result = compact && decimal == 0
      ? number
      : '$number.${decimal.toString().padLeft(2, '0')}';
  return '${negative ? '-' : ''}Rs. $result';
}

String formatAmountForField(int cents) {
  final whole = cents ~/ 100;
  final fraction = cents % 100;
  return fraction == 0
      ? '$whole'
      : '$whole.${fraction.toString().padLeft(2, '0')}';
}

int? parseAmount(String text) {
  final clean = text.replaceAll(',', '').trim();
  if (!RegExp(r'^\d{1,10}(\.\d{1,2})?$').hasMatch(clean)) return null;
  final parts = clean.split('.');
  final whole = int.tryParse(parts[0]);
  if (whole == null) return null;
  final fraction = parts.length > 1
      ? int.parse(parts[1].padRight(2, '0'))
      : 0;
  final cents = whole * 100 + fraction;
  return cents > 0 && cents <= 999999999999 ? cents : null;
}

String monthLabel(DateTime date) => '${monthNames[date.month - 1]} ${date.year}';
String readableDate(DateTime date) => '${date.day} ${shortMonths[date.month - 1]} ${date.year}';
DateTime startOfMonth(DateTime date) => DateTime(date.year, date.month);
DateTime nextMonth(DateTime date) => DateTime(date.year, date.month + 1);
bool isMonth(DateTime value, DateTime month) =>
    value.year == month.year && value.month == month.month;

int sumType(Iterable<MoneyTransaction> records, MoneyType type) =>
    records.where((t) => t.type == type).fold<int>(0, (sum, t) => sum + t.amountCents);

Map<String, int> expenseByCategory(Iterable<MoneyTransaction> records) {
  final totals = <String, int>{};
  for (final t in records) {
    if (t.type == MoneyType.expense) {
      totals.update(t.category, (v) => v + t.amountCents,
          ifAbsent: () => t.amountCents);
    }
  }
  return totals;
}

IconData categoryIcon(String category) {
  switch (category) {
    case 'Food': return Icons.restaurant_outlined;
    case 'Transport': return Icons.directions_car_outlined;
    case 'Shopping': return Icons.shopping_bag_outlined;
    case 'Bills': return Icons.receipt_long_outlined;
    case 'Health': return Icons.favorite_border;
    case 'Education': return Icons.school_outlined;
    case 'Entertainment': return Icons.movie_outlined;
    case 'Housing': return Icons.home_outlined;
    case 'Salary': return Icons.work_outline;
    case 'Business': return Icons.storefront_outlined;
    case 'Freelance': return Icons.laptop_outlined;
    case 'Gift': return Icons.card_giftcard_outlined;
    case 'Investment': return Icons.trending_up;
    default: return Icons.category_outlined;
  }
}

Color categoryColor(String category) {
  const colors = <Color>[
    Color(0xFF1D73E8), Color(0xFF00A99A), Color(0xFFF4A642),
    Color(0xFF8056D9), Color(0xFFE85B8B), Color(0xFF3B8CBD),
    Color(0xFFED7953), Color(0xFF6B74CB), Color(0xFF8395A7),
  ];
  final index = expenseCategories.indexOf(category);
  if (index >= 0) return colors[index % colors.length];
  return brandBlue;
}
