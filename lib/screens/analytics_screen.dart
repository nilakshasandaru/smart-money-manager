import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/money_transaction.dart';
import '../state/money_controller.dart';
import '../utils/money_utils.dart';
import '../widgets/chart_widgets.dart';
import '../widgets/finance_widgets.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool _yearly = false;
  DateTime _month = startOfMonth(DateTime.now());
  int _year = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MoneyController>();
    final records = _yearly
        ? controller.transactionsInYear(_year)
        : controller.transactionsInMonth(_month);
    final income = sumType(records, MoneyType.income);
    final expense = sumType(records, MoneyType.expense);
    final net = income - expense;

    return ListView(padding: const EdgeInsets.fromLTRB(18, 8, 18, 110), children: [
      const Text('Financial analytics', style: TextStyle(
          fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF182B45))),
      const SizedBox(height: 5),
      const Text('Understand how your money changes over time.',
        style: TextStyle(fontSize: 12, color: Color(0xFF8190A6))),
      const SizedBox(height: 18),
      Container(padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(color: const Color(0xFFE4EEFF),
          borderRadius: BorderRadius.circular(15)),
        child: Row(children: [
          Expanded(child: _tab('Monthly chart', false)),
          Expanded(child: _tab('Yearly chart', true)),
        ])),
      const SizedBox(height: 16),
      FinanceCard(padding: const EdgeInsets.symmetric(vertical: 3),
        child: PeriodSwitcher(
          label: _yearly ? 'Year $_year' : monthLabel(_month),
          onPrevious: () => setState(() {
            if (_yearly) { _year--; } else {
              _month = DateTime(_month.year, _month.month - 1);
            }
          }),
          onNext: () => setState(() {
            if (_yearly) { _year++; } else {
              _month = DateTime(_month.year, _month.month + 1);
            }
          }),
          canGoNext: _yearly ? _year < DateTime.now().year
              : nextMonth(_month).isBefore(nextMonth(DateTime.now())),
        )),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: MoneyStat(label: 'Income', amount: income,
            icon: Icons.south_west, color: greenColor)),
        const SizedBox(width: 12),
        Expanded(child: MoneyStat(label: 'Expenses', amount: expense,
            icon: Icons.north_east, color: redColor)),
      ]),
      const SizedBox(height: 13),
      FinanceCard(child: Row(children: [
        Container(padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: paleBlue,
            borderRadius: BorderRadius.circular(13)),
          child: const Icon(Icons.savings_outlined, color: brandBlue)),
        const SizedBox(width: 13),
        const Expanded(child: Text('Net savings (income − expenses)',
          style: TextStyle(color: Color(0xFF61748F), fontSize: 12))),
        Text(formatMoney(net, compact: true),
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
            color: net >= 0 ? brandBlue : redColor)),
      ])),
      const SizedBox(height: 23),
      SectionTitle(_yearly ? 'Income vs Expenses · $_year'
          : 'Daily expenses · ${monthLabel(_month)}'),
      const SizedBox(height: 11),
      FinanceCard(child: _yearly
          ? YearlyComparisonChart(transactions: records, year: _year)
          : MonthlyExpenseChart(transactions: records, month: _month)),
      const SizedBox(height: 23),
      const SectionTitle('Expense categories'),
      const SizedBox(height: 11),
      FinanceCard(child: CategoryDonutChart(transactions: records)),
      const SizedBox(height: 23),
      const SectionTitle('Period summary'),
      const SizedBox(height: 11),
      FinanceCard(child: Column(children: [
        _summary('Total income', formatMoney(income), greenColor),
        const Divider(height: 24, color: Color(0xFFF0F3F9)),
        _summary('Total expenses', formatMoney(expense), redColor),
        const Divider(height: 24, color: Color(0xFFF0F3F9)),
        _summary('Savings rate', income > 0
          ? '${(net / income * 100).toStringAsFixed(1)}%' : '—', brandBlue),
        const Divider(height: 24, color: Color(0xFFF0F3F9)),
        _summary('Transactions', '${records.length}', const Color(0xFF182B45)),
      ])),
    ]);
  }

  Widget _tab(String name, bool yearly) => GestureDetector(
    onTap: () => setState(() => _yearly = yearly),
    child: Container(padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        color: _yearly == yearly ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        boxShadow: _yearly == yearly ? const [BoxShadow(
          color: Color(0x160E47A1), blurRadius: 8)] : null,
      ),
      child: Text(name, textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
            color: _yearly == yearly ? brandBlue : const Color(0xFF7B8AA2))),
    ));

  Widget _summary(String label, String amount, Color color) => Row(children: [
    Expanded(child: Text(label, style: const TextStyle(
      color: Color(0xFF708099), fontSize: 12))),
    Text(amount, style: TextStyle(fontWeight: FontWeight.w800, color: color,
      fontSize: 12)),
  ]);
}
