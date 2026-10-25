import 'package:flutter/material.dart';

import '../models/money_transaction.dart';
import '../utils/money_utils.dart';
import 'analytics_screen.dart';
import 'budget_screen.dart';
import 'dashboard_screen.dart';
import 'settings_screen.dart';
import 'transaction_editor.dart';
import 'transactions_screen.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});
  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _selected = 0;

  Future<void> _openEditor([MoneyTransaction? initial]) async {
    await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => TransactionEditor(initial: initial),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      DashboardScreen(onEdit: _openEditor, onAdd: _openEditor,
        onOpenTransactions: () => setState(() => _selected = 1)),
      TransactionsScreen(onEdit: _openEditor, onAdd: _openEditor),
      const AnalyticsScreen(),
      const BudgetScreen(),
      const SettingsScreen(),
    ];
    return Scaffold(
      body: SafeArea(child: IndexedStack(index: _selected, children: screens)),
      floatingActionButton: _selected == 0 || _selected == 1
          ? FloatingActionButton.extended(
              heroTag: 'add-transaction',
              onPressed: _openEditor,
              backgroundColor: brandBlue,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ) : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selected,
        backgroundColor: Colors.white,
        indicatorColor: paleBlue,
        elevation: 5,
        height: 76,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (index) => setState(() => _selected = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: brandBlue), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long, color: brandBlue), label: 'Activity'),
          NavigationDestination(icon: Icon(Icons.insert_chart_outlined),
            selectedIcon: Icon(Icons.insert_chart, color: brandBlue), label: 'Charts'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet, color: brandBlue), label: 'Budgets'),
          NavigationDestination(icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings, color: brandBlue), label: 'Settings'),
        ],
      ),
    );
  }
}
