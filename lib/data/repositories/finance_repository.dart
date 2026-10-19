import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../../models/transaction_entry.dart';

class FinanceRepository {
  final AppDatabase _database;
  FinanceRepository(this._database);

  Future<List<TransactionEntry>> transactions(
      {String? type, String? search}) async {
    final db = await _database.database;
    final where = <String>[];
    final args = <Object?>[];
    if (type != null && type != 'all') {
      where.add('type = ?');
      args.add(type);
    }
    if (search != null && search.trim().isNotEmpty) {
      where.add('(category LIKE ? OR notes LIKE ? OR payment_method LIKE ?)');
      final q = '%${search.trim()}%';
      args.addAll([q, q, q]);
    }
    final rows = await db.query('transactions',
        where: where.isEmpty ? null : where.join(' AND '),
        whereArgs: args,
        orderBy: 'date DESC, id DESC');
    return rows.map(TransactionEntry.fromMap).toList();
  }

  Future<int> saveTransaction(TransactionEntry item) async {
    final db = await _database.database;
    return db.transaction((txn) async {
      if (item.id == null)
        return txn.insert('transactions', item.toMap()..remove('id'));
      return txn.update('transactions', item.toMap()..remove('id'),
          where: 'id = ?', whereArgs: [item.id]);
    });
  }

  Future<void> deleteTransaction(int id) async {
    final db = await _database.database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, Object?>>> budgets(String month) async {
    final db = await _database.database;
    return db.query('budgets',
        where: 'month = ?', whereArgs: [month], orderBy: 'category');
  }

  Future<void> saveBudget(
      {int? id,
      required String category,
      required double amount,
      required String month}) async {
    final db = await _database.database;
    await db.insert(
        'budgets', {'category': category, 'amount': amount, 'month': month},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<double> sumFor(String type, DateTime start, DateTime end) async {
    final db = await _database.database;
    final result = await db.rawQuery(
        'SELECT COALESCE(SUM(amount), 0) total FROM transactions WHERE type = ? AND date >= ? AND date < ?',
        [type, start.toIso8601String(), end.toIso8601String()]);
    return (result.first['total'] as num).toDouble();
  }
}
