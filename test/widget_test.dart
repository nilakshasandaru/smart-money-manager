import 'package:flutter_test/flutter_test.dart';
import 'package:smart_money_manager/models/money_transaction.dart';
import 'package:smart_money_manager/utils/money_utils.dart';

void main() {
  test('money formatting is accurate in cents', () {
    expect(formatMoney(12345678), 'Rs. 123,456.78');
    expect(formatMoney(-50400), '-Rs. 504.00');
    expect(formatMoney(0, compact: true), 'Rs. 0');
  });

  test('amount parsing avoids floating-point currency rounding', () {
    expect(parseAmount('1,234.50'), 123450);
    expect(parseAmount('0.01'), 1);
    expect(parseAmount('100'), 10000);
    expect(parseAmount('1.234'), isNull);
    expect(parseAmount('0'), isNull);
    expect(parseAmount('-50'), isNull);
  });

  test('income and expense totals are kept separately', () {
    final date = DateTime(2026, 10, 10);
    final records = [
      MoneyTransaction(type: MoneyType.income, amountCents: 1000000,
          category: 'Salary', date: date),
      MoneyTransaction(type: MoneyType.expense, amountCents: 250050,
          category: 'Food', date: date),
      MoneyTransaction(type: MoneyType.expense, amountCents: 100000,
          category: 'Transport', date: date),
    ];
    expect(sumType(records, MoneyType.income), 1000000);
    expect(sumType(records, MoneyType.expense), 350050);
    expect(expenseByCategory(records), {'Food': 250050, 'Transport': 100000});
  });

  test('month boundary handles December to January', () {
    final date = DateTime(2026, 12, 20);
    expect(nextMonth(date), DateTime(2027, 1));
    expect(isMonth(DateTime(2026, 12, 31), date), isTrue);
    expect(isMonth(DateTime(2027, 1, 1), date), isFalse);
  });
}
