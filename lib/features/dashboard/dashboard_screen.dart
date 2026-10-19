import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/finance_repository.dart';
import '../../models/transaction_entry.dart';
import '../transactions/transactions_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _repo = FinanceRepository(AppDatabase.instance);
  late DateTime _month;
  late Future<_DashboardData> _data;
  final _money =
      NumberFormat.currency(locale: 'en_PH', symbol: '₱', decimalDigits: 2);
  @override
  void initState() {
    super.initState();
    _month = DateTime.now();
    _load();
  }

  void _load() => _data = _fetch();
  Future<_DashboardData> _fetch() async {
    final start = DateTime(_month.year, _month.month);
    final end = DateTime(_month.year, _month.month + 1);
    final income = await _repo.sumFor('income', start, end);
    final expenses = await _repo.sumFor('expense', start, end);
    final transactions = await _repo.transactions();
    final budgets = await _repo
        .budgets('${_month.year}-${_month.month.toString().padLeft(2, '0')}');
    final budgetTotal =
        budgets.fold<double>(0, (s, b) => s + (b['amount'] as num).toDouble());
    return _DashboardData(
        income, expenses, transactions.take(5).toList(), budgetTotal);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Budget Tracker'), actions: [
          IconButton(
              tooltip: 'Previous month',
              onPressed: () => setState(() {
                    _month = DateTime(_month.year, _month.month - 1);
                    _load();
                  }),
              icon: const Icon(Icons.chevron_left)),
          Center(
              child: Text(DateFormat.yMMM().format(_month),
                  style: const TextStyle(fontWeight: FontWeight.w600))),
          IconButton(
              tooltip: 'Next month',
              onPressed: () => setState(() {
                    _month = DateTime(_month.year, _month.month + 1);
                    _load();
                  }),
              icon: const Icon(Icons.chevron_right)),
          const SizedBox(width: 8),
        ]),
        body: FutureBuilder<_DashboardData>(
            future: _data,
            builder: (context, s) {
              if (!s.hasData)
                return const Center(child: CircularProgressIndicator());
              final d = s.data!;
              final balance = d.income - d.expenses;
              final spentRatio =
                  d.budget == 0 ? 0.0 : (d.expenses / d.budget).clamp(0.0, 1.0);
              return ListView(padding: const EdgeInsets.all(16), children: [
                Card(
                    child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Monthly balance'),
                              const SizedBox(height: 8),
                              Text(_money.format(balance),
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 18),
                              ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                      value: spentRatio, minHeight: 8)),
                              const SizedBox(height: 8),
                              Text(d.budget == 0
                                  ? 'Set a budget to track spending progress.'
                                  : '${(spentRatio * 100).round()}% of set budget spent'),
                              const SizedBox(height: 8),
                              Text(
                                  'Budget ${_money.format(d.budget)}  ·  Remaining ${_money.format(d.budget - d.expenses)}',
                                  style: Theme.of(context).textTheme.bodySmall),
                            ]))),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _metric('Income', d.income, Colors.green)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _metric('Expenses', d.expenses,
                          Theme.of(context).colorScheme.error)),
                ]),
                const SizedBox(height: 20),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Recent transactions',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      TextButton(
                          onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const TransactionsScreen())),
                          child: const Text('View all')),
                    ]),
                if (d.recent.isEmpty)
                  const Padding(
                      padding: EdgeInsets.all(18),
                      child: Text('Your transactions will appear here.'))
                else
                  ...d.recent.map((t) => Card(
                          child: ListTile(
                        leading: Icon(t.type == 'income'
                            ? Icons.south_west
                            : Icons.north_east),
                        title: Text(t.category),
                        subtitle: Text(DateFormat.yMMMd().format(t.date)),
                        trailing: Text(
                            '${t.type == 'income' ? '+' : '-'}${_money.format(t.amount)}'),
                      ))),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const TransactionsScreen())),
                    icon: const Icon(Icons.add),
                    label: const Text('Add income or expense')),
              ]);
            }),
      );
  Widget _metric(String label, double amount, Color color) => Card(
      child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text(_money.format(amount),
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          ])));
}

class _DashboardData {
  final double income, expenses, budget;
  final List<TransactionEntry> recent;
  _DashboardData(this.income, this.expenses, this.recent, this.budget);
}
