import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/money_controller.dart';
import '../utils/money_utils.dart';
import '../widgets/finance_widgets.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  Future<void> _editBudget(BuildContext context, String category, int current) async {
    final input = TextEditingController(
      text: current == 0 ? '' : formatAmountForField(current));
    final result = await showDialog<int>(context: context, builder: (dialogContext) {
      String? error;
      return StatefulBuilder(builder: (dialogContext, setModalState) => AlertDialog(
        title: Text('$category budget'),
        content: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Monthly limit (LKR). Enter 0 to remove this budget.',
              style: TextStyle(fontSize: 12, color: Color(0xFF61748F))),
            const SizedBox(height: 15),
            TextField(controller: input, keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: InputDecoration(hintText: 'e.g. 12000', prefixText: 'Rs. ',
                errorText: error),
            ),
          ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel')),
          FilledButton(onPressed: () {
            final value = input.text.trim();
            final amount = value == '0' || value == '0.00' || value.isEmpty
                ? 0 : parseAmount(value);
            if (amount == null) {
              setModalState(() => error = 'Enter a valid amount');
              return;
            }
            Navigator.pop(dialogContext, amount);
          }, child: const Text('Save')),
        ],
      ));
    });
    input.dispose();
    if (result == null || !context.mounted) return;
    try {
      await context.read<MoneyController>().saveBudget(category, result);
    } catch (error) {
      showFinanceError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MoneyController>();
    final now = DateTime.now();
    final totalBudget = expenseCategories.fold<int>(0,
        (sum, category) => sum + controller.budgetForCategory(category));
    final spentUnderBudget = expenseCategories.fold<int>(0,
        (sum, category) => controller.budgetForCategory(category) > 0
            ? sum + controller.expenseForCategory(category, now) : sum);
    final active = expenseCategories.where((c) => controller.budgetForCategory(c) > 0).length;

    return ListView(padding: const EdgeInsets.fromLTRB(18, 8, 18, 110), children: [
      const Text('Monthly budgets', style: TextStyle(
        fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF182B45))),
      const SizedBox(height: 5),
      Text('Set a recurring monthly limit for each category · ${monthLabel(now)}',
        style: const TextStyle(fontSize: 12, color: Color(0xFF8190A6))),
      const SizedBox(height: 20),
      Container(padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF287EF2), Color(0xFF124CB5)]),
          borderRadius: BorderRadius.circular(22)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('TOTAL MONTHLY BUDGET', style: TextStyle(
            color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700,
            letterSpacing: 1.2)),
          const SizedBox(height: 9),
          FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
            child: Text(formatMoney(totalBudget), style: const TextStyle(
              color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900))),
          const SizedBox(height: 9),
          Text('$active active categories · ${formatMoney(spentUnderBudget, compact: true)} used',
            style: const TextStyle(fontSize: 12, color: Colors.white70)),
          const SizedBox(height: 15),
          ClipRRect(borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: totalBudget <= 0 ? 0 : (spentUnderBudget / totalBudget).clamp(0.0, 1.0),
              minHeight: 9,
              backgroundColor: Colors.white30,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white))),
        ])),
      const SizedBox(height: 22),
      SectionTitle('Category limits', trailing: Text('$active / ${expenseCategories.length}',
        style: const TextStyle(color: Color(0xFF8190A6), fontSize: 12))),
      const SizedBox(height: 11),
      for (final category in expenseCategories) ...[
        Builder(builder: (context) {
          final limit = controller.budgetForCategory(category);
          final spent = controller.expenseForCategory(category, now);
          final exceeded = limit > 0 && spent > limit;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FinanceCard(child: Column(children: [
              Row(children: [
                Container(width: 42, height: 42, decoration: BoxDecoration(
                  color: categoryColor(category).withValues(alpha: .11),
                  borderRadius: BorderRadius.circular(13)),
                  child: Icon(categoryIcon(category), color: categoryColor(category))),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(category, style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(limit == 0 ? 'No budget set'
                        : '${formatMoney(spent, compact: true)} / ${formatMoney(limit, compact: true)}',
                      style: TextStyle(fontSize: 11,
                        color: exceeded ? redColor : const Color(0xFF8190A6))),
                  ])),
                IconButton(tooltip: 'Edit $category budget',
                    onPressed: () => _editBudget(context, category, limit),
                    icon: const Icon(Icons.edit_outlined, color: brandBlue)),
              ]),
              if (limit > 0) ...[
                const SizedBox(height: 15),
                SpendingProgress(spent: spent, limit: limit),
                if (exceeded) const Align(alignment: Alignment.centerLeft,
                  child: Padding(padding: EdgeInsets.only(top: 5),
                    child: Text('⚠ Monthly budget exceeded',
                      style: TextStyle(color: redColor, fontSize: 11,
                        fontWeight: FontWeight.w700)))),
              ],
            ])),
          );
        }),
      ],
      const Padding(padding: EdgeInsets.only(top: 6), child: Text(
        'Budgets repeat every month. Unbudgeted spending is excluded from the budget progress bar.',
        style: TextStyle(fontSize: 11, color: Color(0xFF8594AA))),
      ),
    ]);
  }
}
