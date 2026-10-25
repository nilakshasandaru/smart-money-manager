import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/money_transaction.dart';
import '../state/money_controller.dart';
import '../utils/money_utils.dart';
import '../widgets/chart_widgets.dart';
import '../widgets/finance_widgets.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.onEdit, required this.onOpenTransactions,
      required this.onAdd});
  final ValueChanged<MoneyTransaction> onEdit;
  final VoidCallback onOpenTransactions;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MoneyController>();
    final now = DateTime.now();
    final monthly = controller.transactionsInMonth(now);
    final income = controller.incomeForMonth(now);
    final expense = controller.expenseForMonth(now);
    final latest = controller.transactions.take(5).toList();

    return ListView(padding: const EdgeInsets.fromLTRB(18, 8, 18, 110), children: [
      Row(children: [
        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Hello, welcome back 👋', style: TextStyle(
            fontSize: 12, color: Color(0xFF7587A0))),
          SizedBox(height: 3),
          Text('Your money overview', style: TextStyle(
            fontSize: 21, fontWeight: FontWeight.w800, color: Color(0xFF182B45))),
        ]),
        const Spacer(),
        CircleAvatar(backgroundColor: paleBlue,
          child: IconButton(tooltip: 'Add transaction', icon: const Icon(Icons.add),
            onPressed: onAdd, color: brandBlue)),
      ]),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF287EF2), Color(0xFF124CB5)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(23),
          boxShadow: const [BoxShadow(color: Color(0x2B1769E0),
            blurRadius: 24, offset: Offset(0, 10))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.account_balance_wallet_outlined, color: Colors.white70, size: 18),
            SizedBox(width: 8),
            Text('TOTAL BALANCE', style: TextStyle(color: Colors.white70,
              fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.3)),
          ]),
          const SizedBox(height: 12),
          FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
            child: Text(formatMoney(controller.balanceCents),
              style: const TextStyle(fontSize: 32, color: Colors.white,
                fontWeight: FontWeight.w900))),
          const SizedBox(height: 19),
          Row(children: [
            const Icon(Icons.calendar_month_outlined, size: 14, color: Colors.white70),
            const SizedBox(width: 6),
            Text('Monthly snapshot · ${monthLabel(now)}',
                style: const TextStyle(fontSize: 11, color: Colors.white70)),
          ]),
        ]),
      ),
      const SizedBox(height: 17),
      Row(children: [
        Expanded(child: MoneyStat(label: 'Income this month', amount: income,
          icon: Icons.south_west, color: greenColor)),
        const SizedBox(width: 11),
        Expanded(child: MoneyStat(label: 'Expenses this month', amount: expense,
          icon: Icons.north_east, color: redColor)),
      ]),
      const SizedBox(height: 23),
      SectionTitle('Monthly expenses', trailing: Text(monthLabel(now),
        style: const TextStyle(fontSize: 11, color: Color(0xFF8292A7)))),
      const SizedBox(height: 12),
      FinanceCard(child: MonthlyExpenseChart(transactions: monthly, month: now)),
      const SizedBox(height: 22),
      const SectionTitle('Spending by category'),
      const SizedBox(height: 12),
      FinanceCard(child: CategoryDonutChart(transactions: monthly)),
      const SizedBox(height: 22),
      SectionTitle('Recent transactions', trailing: TextButton(
          onPressed: onOpenTransactions, child: const Text('See all'))),
      const SizedBox(height: 8),
      FinanceCard(child: latest.isEmpty
        ? const EmptyFinanceState(title: 'No transactions yet',
            subtitle: 'Tap + to record your first income or expense.')
        : Column(children: [
          for (var i = 0; i < latest.length; i++) ...[
            TransactionTile(transaction: latest[i], onTap: () => onEdit(latest[i])),
            if (i != latest.length - 1) const Divider(height: 1, color: Color(0xFFF0F3F9)),
          ],
        ])),
    ]);
  }
}
