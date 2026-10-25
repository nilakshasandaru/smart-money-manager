import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/money_controller.dart';
import '../utils/money_utils.dart';
import '../widgets/finance_widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _editGoal(BuildContext context, int current) async {
    final input = TextEditingController(text: current == 0 ? '' : formatAmountForField(current));
    final result = await showDialog<int>(context: context, builder: (dialogContext) {
      String? error;
      return StatefulBuilder(builder: (dialogContext, setModalState) => AlertDialog(
        title: const Text('Monthly savings goal'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Choose a target savings amount for each month.',
            style: TextStyle(color: Color(0xFF6C7D96), fontSize: 12)),
          const SizedBox(height: 14),
          TextField(controller: input, autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(prefixText: 'Rs. ', hintText: 'e.g. 10000',
              errorText: error)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel')),
          FilledButton(onPressed: () {
            final value = input.text.trim();
            final amount = value.isEmpty || value == '0' || value == '0.00'
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
      await context.read<MoneyController>().saveSavingsGoal(result);
    } catch (error) {
      showFinanceError(context, error);
    }
  }

  Future<void> _addDemo(BuildContext context) async {
    final confirmed = await showDialog<bool>(context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Add sample transactions?'),
          content: const Text('Adds example income and expenses across the last 12 months to preview charts. Available only when no transactions exist.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Add demo data')),
          ],
        ));
    if (confirmed != true || !context.mounted) return;
    try {
      await context.read<MoneyController>().fillDemoData();
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sample transactions added. Open Analytics!')));
    } catch (error) {
      showFinanceError(context, error);
    }
  }

  Future<void> _erase(BuildContext context) async {
    final confirmed = await showDialog<bool>(context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Delete all app data?'),
          content: const Text('This permanently deletes all transactions, budgets, and your savings goal from this phone. This cannot be undone.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete everything', style: TextStyle(color: redColor))),
          ],
        ));
    if (confirmed != true || !context.mounted) return;
    try {
      await context.read<MoneyController>().eraseEverything();
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All local data deleted.')));
    } catch (error) {
      showFinanceError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MoneyController>();
    final now = DateTime.now();
    final netSavings = controller.incomeForMonth(now) - controller.expenseForMonth(now);
    final target = controller.savingsGoalCents;

    return ListView(padding: const EdgeInsets.fromLTRB(18, 8, 18, 110), children: [
      const Text('Settings & goals', style: TextStyle(
        fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF182B45))),
      const SizedBox(height: 5),
      const Text('Manage your savings target and local app data.',
        style: TextStyle(fontSize: 12, color: Color(0xFF8190A6))),
      const SizedBox(height: 20),
      const SectionTitle('Monthly savings'),
      const SizedBox(height: 12),
      FinanceCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const CircleAvatar(backgroundColor: paleBlue,
                child: Icon(Icons.savings_outlined, color: brandBlue)),
            const SizedBox(width: 12),
            const Expanded(child: Text('Savings goal', style: TextStyle(
                fontWeight: FontWeight.w800))),
            IconButton(tooltip: 'Edit savings goal',
                onPressed: () => _editGoal(context, target),
                icon: const Icon(Icons.edit_outlined, color: brandBlue)),
          ]),
          const SizedBox(height: 14),
          Text(target == 0 ? 'No savings target set' : formatMoney(target),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900,
              color: Color(0xFF1A3252))),
          const SizedBox(height: 5),
          Text('Net savings this month: ${formatMoney(netSavings, compact: true)}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF7B8AA2))),
          if (target > 0) ...[
            const SizedBox(height: 14),
            SpendingProgress(spent: netSavings < 0 ? 0 : netSavings, limit: target, goalMode: true),
          ],
          const SizedBox(height: 8),
          const Text('Net savings = monthly income − monthly expenses. This is not a separate savings account.',
            style: TextStyle(fontSize: 11, color: Color(0xFF8292A9))),
        ],
      )),
      const SizedBox(height: 25),
      const SectionTitle('Preferences'),
      const SizedBox(height: 12),
      FinanceCard(child: Column(children: [
        const _SettingRow(icon: Icons.payments_outlined, title: 'Currency', subtitle: 'Sri Lankan Rupee (LKR)'),
        const Divider(height: 20),
        const _SettingRow(icon: Icons.cloud_off_outlined, title: 'Data storage', subtitle: 'Offline SQLite · stored on this device'),
        const Divider(height: 20),
        const _SettingRow(icon: Icons.color_lens_outlined, title: 'Theme', subtitle: 'Blue · Light mode'),
      ])),
      const SizedBox(height: 25),
      const SectionTitle('Data tools'),
      const SizedBox(height: 12),
      FinanceCard(child: Column(children: [
        ListTile(contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.science_outlined, color: brandBlue),
          title: const Text('Add sample data', style: TextStyle(fontWeight: FontWeight.w700)),
          subtitle: const Text('Preview 12 months of charts'),
          trailing: const Icon(Icons.chevron_right),
          enabled: controller.transactions.isEmpty,
          onTap: () => _addDemo(context)),
        const Divider(height: 12),
        ListTile(contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.delete_forever_outlined, color: redColor),
          title: const Text('Delete all local data',
            style: TextStyle(color: redColor, fontWeight: FontWeight.w700)),
          subtitle: const Text('Irreversible · no cloud backup'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _erase(context)),
      ])),
      const SizedBox(height: 24),
      const Center(child: Text('Smart Money Manager  •  v1.0.0',
        style: TextStyle(fontSize: 11, color: Color(0xFF91A0B4)))),
    ]);
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, color: brandBlue),
    const SizedBox(width: 14),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height: 3),
      Text(subtitle, style: const TextStyle(color: Color(0xFF8190A6), fontSize: 11)),
    ])),
  ]);
}
