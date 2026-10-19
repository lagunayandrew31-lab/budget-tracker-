import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../../data/database/app_database.dart';
import 'settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          Text('Appearance', style: Theme.of(context).textTheme.titleMedium),
          Card(
              child: SwitchListTile(
                  title: const Text('Dark theme'),
                  subtitle: const Text('Use a darker interface'),
                  value: ref.watch(themeModeProvider),
                  onChanged: (v) =>
                      ref.read(themeModeProvider.notifier).setDark(v))),
          const SizedBox(height: 18),
          Text('Data and privacy',
              style: Theme.of(context).textTheme.titleMedium),
          Card(
              child: Column(children: [
            ListTile(
                leading: const Icon(Icons.ios_share),
                title: const Text('Export local data'),
                subtitle: const Text('Create a JSON backup on this device'),
                onTap: () async {
                  final db = await AppDatabase.instance.database;
                  final data = <String, dynamic>{};
                  for (final table in [
                    'transactions',
                    'budgets',
                    'goals',
                    'bills',
                    'categories'
                  ]) {
                    data[table] = await db.query(table);
                  }
                  final dir = await getTemporaryDirectory();
                  final file = File('${dir.path}/budget_tracker_backup.json');
                  await file.writeAsString(
                      const JsonEncoder.withIndent('  ').convert(data));
                  await Share.shareXFiles([XFile(file.path)],
                      text: 'Budget Tracker local backup');
                }),
            const Divider(height: 1),
            ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Clear all local data'),
                subtitle: const Text(
                    'Permanently delete transactions, budgets, bills and goals'),
                onTap: () async {
                  final confirm = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                              title: const Text('Clear all data?'),
                              content: const Text(
                                  'This cannot be undone. Export a backup first if needed.'),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(c, false),
                                    child: const Text('Cancel')),
                                TextButton(
                                    onPressed: () => Navigator.pop(c, true),
                                    child: const Text('Clear data'))
                              ]));
                  if (confirm == true) {
                    final db = await AppDatabase.instance.database;
                    await db.transaction((txn) async {
                      for (final table in [
                        'transactions',
                        'budgets',
                        'goals',
                        'bills'
                      ]) await txn.delete(table);
                    });
                    if (context.mounted)
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Local financial data cleared.')));
                  }
                }),
          ])),
          const SizedBox(height: 18),
          Text('Legal', style: Theme.of(context).textTheme.titleMedium),
          Card(
              child: Column(children: [
            ListTile(
                title: const Text('Privacy policy'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const LegalPage(
                            title: 'Privacy policy', body: _privacy)))),
            const Divider(height: 1),
            ListTile(
                title: const Text('Terms and conditions'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const LegalPage(
                            title: 'Terms and conditions', body: _terms)))),
          ])),
          const SizedBox(height: 12),
          const Text(
              'Budget Tracker stores financial records locally. Keep backups secure. This app does not connect to a bank or provide financial advice.',
              style: TextStyle(fontSize: 12)),
        ]),
      );
}

const _privacy = '''Privacy Policy

Budget Tracker is designed for offline personal use. Financial entries, budgets, bills, savings goals and preferences are stored on your device.

Data collection
This app does not require an account and does not intentionally send your financial data to a developer-operated server. Exported backups are created only when you request them and may be shared using your device's sharing options.

Device permissions
Notifications may be used for reminders. Biometric or device authentication may be added if enabled in a future version. This starter build does not enable biometric app locking.

Your choices
You can delete local records from Settings. Uninstalling the app may remove its local database. Exported files may remain in locations you choose and should be protected.

Security
No local application can guarantee protection against a compromised or shared device. Use your device lock and keep backup files private.

Contact
Before public release, replace this section with the developer's real support contact and review this policy for the actual distribution and data practices.''';

const _terms = '''Terms and Conditions

Budget Tracker is provided as a personal record-keeping tool. You are responsible for the accuracy of entries and for maintaining backups of important data.

No financial advice
Displayed balances, budgets and reports are calculations based on information entered into the app. They are not financial, tax, legal or investment advice.

Local data
Data is stored on your device. You are responsible for securing your device and any exported backup. Clearing data or uninstalling the app may result in data loss.

Availability
The app is provided without a guarantee that it will be uninterrupted or error-free. Notification delivery depends on device and operating-system settings.

Changes
These terms should be reviewed and customized by the publisher before distribution.

Contact
Add the publisher's real support contact before releasing this app publicly.''';

class LegalPage extends StatelessWidget {
  final String title, body;
  const LegalPage({super.key, required this.title, required this.body});
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Text(body,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(height: 1.55))));
}
