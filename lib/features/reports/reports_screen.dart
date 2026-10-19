import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/finance_repository.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _repo = FinanceRepository(AppDatabase.instance);
  late Future<List<double>> _future;
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => _future = _fetch();
  Future<List<double>> _fetch() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - 5);
    final values = <double>[];
    for (var i = 0; i < 6; i++) {
      final d = DateTime(start.year, start.month + i);
      values
          .add(await _repo.sumFor('expense', d, DateTime(d.year, d.month + 1)));
    }
    return values;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Reports')),
        body: FutureBuilder<List<double>>(
            future: _future,
            builder: (context, s) {
              if (!s.hasData)
                return const Center(child: CircularProgressIndicator());
              final vals = s.data!;
              return ListView(padding: const EdgeInsets.all(16), children: [
                Text('Monthly expenses',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Card(
                    child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 24, 16, 16),
                        child: SizedBox(
                            height: 250,
                            child: BarChart(BarChartData(
                              gridData: const FlGridData(show: true),
                              borderData: FlBorderData(show: false),
                              titlesData: FlTitlesData(
                                  leftTitles: const AxisTitles(
                                      sideTitles: SideTitles(
                                          showTitles: true, reservedSize: 42)),
                                  bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (v, m) {
                                            final d = DateTime(
                                                DateTime.now().year,
                                                DateTime.now().month -
                                                    5 +
                                                    v.toInt());
                                            return Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 8),
                                                child: Text(
                                                    DateFormat.MMM().format(d),
                                                    style: const TextStyle(
                                                        fontSize: 11)));
                                          }))),
                              barGroups: List.generate(
                                  vals.length,
                                  (i) => BarChartGroupData(x: i, barRods: [
                                        BarChartRodData(
                                            toY: vals[i],
                                            width: 18,
                                            borderRadius:
                                                BorderRadius.circular(3),
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary)
                                      ])),
                            ))))),
                const SizedBox(height: 16),
                const Text(
                    'Amounts are calculated from transactions saved on this device.'),
              ]);
            }),
      );
}
