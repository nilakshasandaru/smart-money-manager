import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/money_budget.dart';
import '../models/money_transaction.dart';

class MoneyDatabase {
  Database? _database;

  Future<Database> get instance async {
    if (_database != null) return _database!;
    final path = p.join(await getDatabasesPath(), 'smart_money_manager.db');
    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT NOT NULL CHECK(type IN ('income', 'expense')),
            amount_cents INTEGER NOT NULL CHECK(amount_cents > 0),
            category TEXT NOT NULL,
            note TEXT NOT NULL DEFAULT '',
            date TEXT NOT NULL
          )
        ''');
        await db.execute('CREATE INDEX idx_transaction_date ON transactions(date DESC)');
        await db.execute('''
          CREATE TABLE budgets (
            category TEXT PRIMARY KEY,
            amount_cents INTEGER NOT NULL CHECK(amount_cents >= 0)
          )
        ''');
        await db.execute('''
          CREATE TABLE preferences (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
      },
    );
    return _database!;
  }

  Future<List<MoneyTransaction>> getTransactions() async {
    final db = await instance;
    final rows = await db.query('transactions', orderBy: 'date DESC, id DESC');
    return rows.map(MoneyTransaction.fromMap).toList();
  }

  Future<int> addTransaction(MoneyTransaction transaction) async =>
      (await instance).insert('transactions', transaction.toMap());

  Future<void> updateTransaction(MoneyTransaction transaction) async {
    if (transaction.id == null) throw ArgumentError('Missing transaction ID');
    final changes = Map<String, Object?>.from(transaction.toMap())..remove('id');
    await (await instance).update('transactions', changes,
        where: 'id = ?', whereArgs: [transaction.id]);
  }

  Future<void> deleteTransaction(int id) async {
    await (await instance).delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<MoneyBudget>> getBudgets() async {
    final db = await instance;
    final rows = await db.query('budgets');
    return rows.map(MoneyBudget.fromMap).toList();
  }

  Future<void> setBudget(String category, int amountCents) async {
    final db = await instance;
    if (amountCents == 0) {
      await db.delete('budgets', where: 'category = ?', whereArgs: [category]);
    } else {
      await db.insert('budgets', {
        'category': category,
        'amount_cents': amountCents,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<int> getSavingsGoal() async {
    final db = await instance;
    final rows = await db.query('preferences',
        columns: ['value'], where: 'key = ?', whereArgs: ['savings_goal'], limit: 1);
    return rows.isEmpty ? 0 : int.tryParse(rows.first['value'] as String) ?? 0;
  }

  Future<void> setSavingsGoal(int cents) async {
    await (await instance).insert('preferences', {
      'key': 'savings_goal',
      'value': cents.toString(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> addDemoData(DateTime today) async {
    final db = await instance;
    await db.transaction((txn) async {
      final count = Sqflite.firstIntValue(
          await txn.rawQuery('SELECT COUNT(*) FROM transactions')) ?? 0;
      if (count > 0) throw StateError('Demo data can only be added to an empty app.');
      for (var i = 0; i < 12; i++) {
        final month = DateTime(today.year, today.month - i);
        final rows = <MoneyTransaction>[
          MoneyTransaction(type: MoneyType.income, amountCents: (65000 + i * 1500) * 100,
              category: 'Salary', note: 'Demo salary', date: DateTime(month.year, month.month, 2)),
          MoneyTransaction(type: MoneyType.income, amountCents: (6000 + i * 300) * 100,
              category: 'Freelance', note: 'Demo side income', date: DateTime(month.year, month.month, 4)),
          MoneyTransaction(type: MoneyType.expense, amountCents: (16500 + i * 170) * 100,
              category: 'Food', note: 'Demo groceries', date: DateTime(month.year, month.month, 6)),
          MoneyTransaction(type: MoneyType.expense, amountCents: (5800 + i * 100) * 100,
              category: 'Transport', note: 'Demo travel', date: DateTime(month.year, month.month, 8)),
          MoneyTransaction(type: MoneyType.expense, amountCents: (12000 + i * 150) * 100,
              category: 'Housing', note: 'Demo rent', date: DateTime(month.year, month.month, 10)),
          MoneyTransaction(type: MoneyType.expense, amountCents: (4500 + i * 60) * 100,
              category: 'Bills', note: 'Demo utilities', date: DateTime(month.year, month.month, 13)),
          MoneyTransaction(type: MoneyType.expense, amountCents: (2200 + i * 70) * 100,
              category: 'Shopping', note: 'Demo purchase', date: DateTime(month.year, month.month, 17)),
        ];
        for (final row in rows) {
          // Avoid creating future-dated demo records in the current month.
          if (row.date.isAfter(today)) continue;
          await txn.insert('transactions', row.toMap());
        }
      }
    });
  }

  Future<void> clearAll() async {
    final db = await instance;
    await db.transaction((txn) async {
      await txn.delete('transactions');
      await txn.delete('budgets');
      await txn.delete('preferences');
    });
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
