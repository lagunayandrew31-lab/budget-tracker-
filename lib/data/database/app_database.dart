import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) {
      return _db!;
    }

    // Initialize the correct database factory for the current platform.
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
    }

    // Use a web-compatible database path in Chrome.
    final String dbPath = kIsWeb
        ? 'budget_tracker.db'
        : join(
            await getDatabasesPath(),
            'budget_tracker.db',
          );

    _db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (Database db, int version) async {
        // Transactions table
        await db.execute('''
          CREATE TABLE transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT NOT NULL,
            amount REAL NOT NULL CHECK(amount > 0),
            category TEXT NOT NULL,
            date TEXT NOT NULL,
            payment_method TEXT NOT NULL,
            notes TEXT NOT NULL DEFAULT '',
            recurring INTEGER NOT NULL DEFAULT 0
          )
        ''');

        // Budgets table
        await db.execute('''
          CREATE TABLE budgets (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            category TEXT NOT NULL,
            amount REAL NOT NULL CHECK(amount > 0),
            month TEXT NOT NULL,
            UNIQUE(category, month)
          )
        ''');

        // Savings goals table
        await db.execute('''
          CREATE TABLE goals (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            target REAL NOT NULL CHECK(target > 0),
            saved REAL NOT NULL DEFAULT 0,
            target_date TEXT
          )
        ''');

        // Bills table
        await db.execute('''
          CREATE TABLE bills (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            amount REAL NOT NULL CHECK(amount > 0),
            due_date TEXT NOT NULL,
            paid INTEGER NOT NULL DEFAULT 0,
            repeat_period TEXT NOT NULL DEFAULT 'None'
          )
        ''');

        // Categories table
        await db.execute('''
          CREATE TABLE categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
            type TEXT NOT NULL,
            color INTEGER NOT NULL DEFAULT 3889739
          )
        ''');

        // Default expense categories
        final List<String> expenseCategories = [
          'Food',
          'Transportation',
          'Bills',
          'Shopping',
          'Health',
          'Education',
          'Entertainment',
          'Savings',
        ];

        for (final String category in expenseCategories) {
          await db.insert(
            'categories',
            {
              'name': category,
              'type': 'expense',
              'color': 3889739,
            },
          );
        }

        // Default income categories
        final List<String> incomeCategories = [
          'Salary',
          'Business',
          'Allowance',
          'Other Income',
        ];

        for (final String category in incomeCategories) {
          await db.insert(
            'categories',
            {
              'name': category,
              'type': 'income',
              'color': 3889739,
            },
          );
        }
      },
    );


    return _db!;   }
  
  
}