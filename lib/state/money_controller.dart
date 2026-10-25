import 'package:flutter/foundation.dart';

import '../data/money_database.dart';
import '../models/money_budget.dart';
import '../models/money_transaction.dart';
import '../utils/money_utils.dart';

class MoneyController extends ChangeNotifier {
  MoneyController(this._storage);

  final MoneyDatabase _storage;
  List<MoneyTransaction> _transactions = [];
  List<MoneyBudget> _budgets = [];
  int _savingsGoalCents = 0;

  List<MoneyTransaction> get transactions => List.unmodifiable(_transactions);
  List<MoneyBudget> get budgets => List.unmodifiable(_budgets);
  int get savingsGoalCents => _savingsGoalCents;

  Future<void> initialize() async => refresh();

  Future<void> refresh() async {
    _transactions = await _storage.getTransactions();
    _budgets = await _storage.getBudgets();
    _savingsGoalCents = await _storage.getSavingsGoal();
    notifyListeners();
  }

  Future<void> saveTransaction(MoneyTransaction transaction) async {
    if (transaction.amountCents <= 0) throw ArgumentError('Amount must be positive');
    if (transaction.id == null) {
      await _storage.addTransaction(transaction);
    } else {
      await _storage.updateTransaction(transaction);
    }
    await refresh();
  }

  Future<void> removeTransaction(int id) async {
    await _storage.deleteTransaction(id);
    await refresh();
  }

  Future<void> saveBudget(String category, int amountCents) async {
    if (amountCents < 0) throw ArgumentError('Budget must be positive');
    await _storage.setBudget(category, amountCents);
    await refresh();
  }

  Future<void> saveSavingsGoal(int cents) async {
    if (cents < 0) throw ArgumentError('Goal must be positive');
    await _storage.setSavingsGoal(cents);
    await refresh();
  }

  Future<void> fillDemoData() async {
    await _storage.addDemoData(DateTime.now());
    await refresh();
  }

  Future<void> eraseEverything() async {
    await _storage.clearAll();
    await refresh();
  }

  List<MoneyTransaction> transactionsInMonth(DateTime month) => _transactions
      .where((t) => isMonth(t.date, month)).toList();

  List<MoneyTransaction> transactionsInYear(int year) =>
      _transactions.where((t) => t.date.year == year).toList();

  int get totalIncomeCents => sumType(_transactions, MoneyType.income);
  int get totalExpenseCents => sumType(_transactions, MoneyType.expense);
  int get balanceCents => totalIncomeCents - totalExpenseCents;

  int incomeForMonth(DateTime month) =>
      sumType(transactionsInMonth(month), MoneyType.income);
  int expenseForMonth(DateTime month) =>
      sumType(transactionsInMonth(month), MoneyType.expense);

  int expenseForCategory(String category, DateTime month) =>
      transactionsInMonth(month)
          .where((t) => t.type == MoneyType.expense && t.category == category)
          .fold<int>(0, (sum, t) => sum + t.amountCents);

  int budgetForCategory(String category) {
    for (final budget in _budgets) {
      if (budget.category == category) return budget.amountCents;
    }
    return 0;
  }

  @override
  void dispose() {
    _storage.close();
    super.dispose();
  }
}
