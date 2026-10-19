import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/finance_repository.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});
  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  final _repo = FinanceRepository(AppDatabase.instance);
  final _money =
      NumberFormat.currency(locale: 'en_PH', symbol: '₱', decimalDigits: 2);
  late DateTime _month;
  late Future<List<Map<String, Object?>>> _future;
  @override
  void initState() {
    super.initState();
    _month = DateTime.now();
    _load();
  }

  String get _monthKey =>
      '${_month.year}-${_month.month.toString().padLeft(2, '0')}';
  void _load() => _future = _repo.budgets(_monthKey);
  Future<void> _add() async {
    final categories = [
      'Overall',
      'Food',
      'Transportation',
      'Bills',
      'Shopping',
      'Health',
      'Education',
      'Entertainment',
      'Savings'
    ];
    String category = 'Overall';
    final amount = TextEditingController();
    final ok = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
            builder: (context, setD) => AlertDialog(
                  title: const Text('Set budget'),
                  content: Column(mainAxisSize: MainAxisSize.min, children: [
                    DropdownButtonFormField<String>(
                        value: category,
                        items: categories
                            .map((c) =>
                                DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (v) => setD(() => category = v ?? category)),
                    const SizedBox(height: 12),
                    TextField(
                        controller: amount,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                            labelText: 'Budget amount (₱)')),
                  ]),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel')),
                    ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Save'))
                  ],
                )));
    final value = double.tryParse(amount.text);
    if (ok == true && value != null && value > 0) {
      await _repo.saveBudget(
          category: category, amount: value, month: _monthKey);
      setState(_load);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Budgets'), actions: [
          IconButton(
              onPressed: () => setState(() => _month =
                  DateTime(_month.year, _month.month - 1)..also((_) {})),
              icon: const Icon(Icons.chevron_left)),
          Center(child: Text(DateFormat.yMMM().format(_month))),
          IconButton(
              onPressed: () => setState(
                  () => _month = DateTime(_month.year, _month.month + 1)),
              icon: const Icon(Icons.chevron_right)),
        ]),
        floatingActionButton: FloatingActionButton.extended(
            onPressed: _add,
            icon: const Icon(Icons.add),
            label: const Text('Set budget')),
        body: FutureBuilder<List<Map<String, Object?>>>(
            future: _future,
            builder: (context, s) {
              if (!s.hasData)
                return const Center(child: CircularProgressIndicator());
              if (s.data!.isEmpty)
                return const Center(
                    child: Text(
                        'No budgets for this month. Add one to start tracking.'));
              return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: s.data!.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final b = s.data![i];
                    final amount = (b['amount'] as num).toDouble();
                    return Card(
                        child: ListTile(
                            title: Text(b['category'] as String),
                            subtitle: Text('Budget ${_money.format(amount)}'),
                            trailing: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () async {
                                  final db =
                                      await AppDatabase.instance.database;
                                  await db.delete('budgets',
                                      where: 'id = ?', whereArgs: [b['id']]);
                                  setState(_load);
                                })));
                  });
            }),
      );
}

extension on DateTime {
  DateTime also(void Function(DateTime) fn) {
    fn(this);
    return this;
  }
}
