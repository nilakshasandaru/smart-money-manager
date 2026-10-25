import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/money_transaction.dart';
import '../utils/money_utils.dart';
import 'finance_widgets.dart';

class MonthlyExpenseChart extends StatelessWidget {
  const MonthlyExpenseChart({super.key, required this.transactions, required this.month});
  final List<MoneyTransaction> transactions;
  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final dayCount = DateTime(month.year, month.month + 1, 0).day;
    final values = List<int>.filled(dayCount, 0);
    for (final t in transactions) {
      if (t.type == MoneyType.expense && isMonth(t.date, month)) {
        values[t.date.day - 1] += t.amountCents;
      }
    }
    final maxValue = values.fold<int>(0, math.max);
    if (maxValue == 0) return const EmptyFinanceState(
      icon: Icons.bar_chart_outlined, title: 'No monthly spending yet',
      subtitle: 'Add expenses to see your daily spending chart.',
    );
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.bar_chart, size: 15, color: brandBlue),
        const SizedBox(width: 7),
        const Text('Daily expenses', style: TextStyle(fontSize: 12,
          fontWeight: FontWeight.w600, color: Color(0xFF70829C))),
        const Spacer(),
        Text('Peak ${formatMoney(maxValue, compact: true)}',
          style: const TextStyle(color: Color(0xFF8A97AC), fontSize: 10)),
      ]),
      const SizedBox(height: 20),
      SizedBox(height: 150, child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(dayCount, (index) {
          final heightFactor = maxValue == 0 ? 0.0 : values[index] / maxValue;
          return Expanded(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Column(children: [
              Expanded(child: Align(alignment: Alignment.bottomCenter,
                child: FractionallySizedBox(
                  heightFactor: heightFactor.clamp(0.015, 1.0),
                  widthFactor: 1,
                  child: DecoratedBox(decoration: BoxDecoration(
                    color: values[index] == 0
                        ? const Color(0xFFE9EFF9) : brandBlue,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                  )),
                ))),
              const SizedBox(height: 7),
              SizedBox(height: 16, child: Text(
                (index == 0 || (index + 1) % 5 == 0) ? '${index + 1}' : '',
                style: const TextStyle(fontSize: 9, color: Color(0xFF8292A9)),
              )),
            ]),
          ));
        }),
      )),
    ]);
  }
}

class YearlyComparisonChart extends StatelessWidget {
  const YearlyComparisonChart({super.key, required this.transactions, required this.year});
  final List<MoneyTransaction> transactions;
  final int year;

  @override
  Widget build(BuildContext context) {
    final income = List<int>.filled(12, 0);
    final expense = List<int>.filled(12, 0);
    for (final t in transactions) {
      if (t.date.year != year) continue;
      if (t.type == MoneyType.income) {
        income[t.date.month - 1] += t.amountCents;
      } else {
        expense[t.date.month - 1] += t.amountCents;
      }
    }
    final maxValue = [...income, ...expense].fold<int>(0, math.max);
    if (maxValue == 0) return const EmptyFinanceState(
      icon: Icons.stacked_bar_chart_outlined,
      title: 'No data for this year',
      subtitle: 'Income and expense comparisons appear here.',
    );
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _legendDot(greenColor, 'Income'), const SizedBox(width: 22),
        _legendDot(brandBlue, 'Expense'),
      ]),
      const SizedBox(height: 19),
      SizedBox(height: 174, child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(12, (i) => Expanded(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Column(children: [
            Expanded(child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(child: _columnBar(income[i] / maxValue, greenColor)),
              const SizedBox(width: 2),
              Expanded(child: _columnBar(expense[i] / maxValue, brandBlue)),
            ])),
            const SizedBox(height: 9),
            Text(shortMonths[i],
                style: const TextStyle(fontSize: 10, color: Color(0xFF8292A9))),
          ]),
        ))),
      )),
      const SizedBox(height: 6),
      const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Jan', style: TextStyle(fontSize: 10, color: Color(0xFF8292A9))),
        Text('Dec', style: TextStyle(fontSize: 10, color: Color(0xFF8292A9))),
      ]),
    ]);
  }

  Widget _columnBar(double ratio, Color color) => Align(
    alignment: Alignment.bottomCenter,
    child: FractionallySizedBox(
      heightFactor: ratio.clamp(0.012, 1.0), widthFactor: 1,
      child: DecoratedBox(decoration: BoxDecoration(color: color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))),
    ),
  );
}

Widget _legendDot(Color color, String name) => Row(mainAxisSize: MainAxisSize.min,
  children: [
    Container(width: 9, height: 9, decoration: BoxDecoration(
      color: color, borderRadius: BorderRadius.circular(3))),
    const SizedBox(width: 6),
    Text(name, style: const TextStyle(fontSize: 11, color: Color(0xFF62748E))),
  ]);

class CategoryDonutChart extends StatelessWidget {
  const CategoryDonutChart({super.key, required this.transactions});
  final List<MoneyTransaction> transactions;

  @override
  Widget build(BuildContext context) {
    final entries = expenseByCategory(transactions).entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold<int>(0, (sum, entry) => sum + entry.value);
    if (total == 0) return const EmptyFinanceState(
      icon: Icons.donut_large_outlined, title: 'No categories to show',
      subtitle: 'Add expenses to see your spending breakdown.',
    );
    return LayoutBuilder(builder: (context, constraints) {
      final narrow = constraints.maxWidth < 290;
      final donut = SizedBox(width: 140, height: 140,
          child: Stack(alignment: Alignment.center, children: [
            CustomPaint(size: const Size(140, 140),
                painter: _DonutPainter(entries, total)),
            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('Spent', style: TextStyle(fontSize: 10, color: Color(0xFF8090A6))),
              Text(formatMoney(total, compact: true), textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
            ]),
          ]));
      final legend = Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: entries.take(6).map((entry) {
          final percent = entry.value * 100 / total;
          return Padding(padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(children: [
              Container(width: 9, height: 9, decoration: BoxDecoration(
                color: categoryColor(entry.key), shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Expanded(child: Text(entry.key, maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: Color(0xFF556985)))),
              Text('${percent.toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
            ]));
        }).toList(),
      );
      return narrow
          ? Column(children: [donut, const SizedBox(height: 12), legend])
          : Row(children: [donut, const SizedBox(width: 16), Expanded(child: legend)]);
    });
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter(this.entries, this.total);
  final List<MapEntry<String, int>> entries;
  final int total;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Rect.fromCircle(center: size.center(Offset.zero),
      radius: size.width / 2 - 10);
    var start = -math.pi / 2;
    for (final entry in entries) {
      final sweep = 2 * math.pi * entry.value / total;
      canvas.drawArc(bounds, start, sweep, false, Paint()
        ..color = categoryColor(entry.key)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 17
        ..strokeCap = StrokeCap.butt);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.entries != entries || oldDelegate.total != total;
}
