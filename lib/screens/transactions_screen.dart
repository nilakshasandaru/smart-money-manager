import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/money_transaction.dart';
import '../state/money_controller.dart';
import '../utils/money_utils.dart';
import '../widgets/finance_widgets.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key, required this.onEdit, required this.onAdd});
  final ValueChanged<MoneyTransaction> onEdit;
  final VoidCallback onAdd;

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  DateTime _month = startOfMonth(DateTime.now());
  MoneyType? _filter;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MoneyController>();
    final monthItems = controller.transactionsInMonth(_month);
    final filtered = monthItems.where((t) {
      if (_filter != null && t.type != _filter) return false;
      final search = _query.toLowerCase().trim();
      return search.isEmpty || t.category.toLowerCase().contains(search)
          || t.note.toLowerCase().contains(search)
          || formatMoney(t.amountCents).toLowerCase().contains(search);
    }).toList();
    final income = sumType(monthItems, MoneyType.income);
    final expense = sumType(monthItems, MoneyType.expense);

    return ListView(padding: const EdgeInsets.fromLTRB(18, 8, 18, 110), children: [
      const Text('Transaction history', style: TextStyle(
        fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF182B45))),
      const SizedBox(height: 5),
      const Text('Search, filter and update your records.',
        style: TextStyle(fontSize: 12, color: Color(0xFF8190A6))),
      const SizedBox(height: 17),
      FinanceCard(padding: const EdgeInsets.symmetric(vertical: 3),
        child: PeriodSwitcher(
          label: monthLabel(_month),
          onPrevious: () => setState(() => _month = DateTime(_month.year, _month.month - 1)),
          onNext: () => setState(() => _month = DateTime(_month.year, _month.month + 1)),
          canGoNext: nextMonth(_month).isBefore(nextMonth(DateTime.now())),
        )),
      const SizedBox(height: 13),
      Row(children: [
        Expanded(child: MoneyStat(label: 'Income', amount: income,
            icon: Icons.south_west, color: greenColor)),
        const SizedBox(width: 12),
        Expanded(child: MoneyStat(label: 'Expenses', amount: expense,
            icon: Icons.north_east, color: redColor)),
      ]),
      const SizedBox(height: 17),
      TextField(onChanged: (value) => setState(() => _query = value),
        decoration: const InputDecoration(hintText: 'Search category or note',
          prefixIcon: Icon(Icons.search))),
      const SizedBox(height: 11),
      SingleChildScrollView(scrollDirection: Axis.horizontal,
        child: Row(children: [
          _chip('All', null), const SizedBox(width: 7),
          _chip('Income', MoneyType.income), const SizedBox(width: 7),
          _chip('Expenses', MoneyType.expense),
        ])),
      const SizedBox(height: 17),
      SectionTitle('${filtered.length} transactions'),
      const SizedBox(height: 9),
      FinanceCard(child: filtered.isEmpty
          ? Column(children: [
              const EmptyFinanceState(title: 'Nothing found',
                subtitle: 'Try another month or filter, or add a transaction.',
                icon: Icons.search_off_outlined),
              FilledButton.icon(onPressed: widget.onAdd,
                icon: const Icon(Icons.add), label: const Text('Add transaction')),
            ])
          : Column(children: [
              for (var i = 0; i < filtered.length; i++) ...[
                TransactionTile(transaction: filtered[i],
                    onTap: () => widget.onEdit(filtered[i])),
                if (i < filtered.length - 1)
                  const Divider(height: 1, color: Color(0xFFF0F3F9)),
              ],
            ])),
    ]);
  }

  Widget _chip(String title, MoneyType? type) => ChoiceChip(
    label: Text(title),
    selected: _filter == type,
    selectedColor: paleBlue,
    checkmarkColor: brandBlue,
    labelStyle: TextStyle(color: _filter == type ? brandBlue : const Color(0xFF6F7F94)),
    side: const BorderSide(color: Color(0xFFDCE5F3)),
    onSelected: (_) => setState(() => _filter = type),
  );
}
