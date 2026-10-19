import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/database/app_database.dart';
import '../../data/repositories/finance_repository.dart';
import '../../models/transaction_entry.dart';
import '../../services/notification_service.dart';

final NumberFormat _money = NumberFormat.currency(
  locale: 'en_PH',
  symbol: '₱',
  decimalDigits: 2,
);

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final FinanceRepository _repo = FinanceRepository(AppDatabase.instance);

  final TextEditingController _searchController = TextEditingController();

  String _type = 'all';
  String _search = '';

  late Future<List<TransactionEntry>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = _repo.transactions(
      type: _type,
      search: _search,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _add({TransactionEntry? item}) async {
    final result = await showModalBottomSheet<TransactionEntry>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => TransactionForm(item: item),
    );

    if (!mounted || result == null) return;

    try {
      await _repo.saveTransaction(result);

      if (!mounted) return;

      setState(_reload);

      try {
        await NotificationService.instance.showBudgetNotice(
          'Transaction saved',
          '${result.type == 'income' ? 'Income' : 'Expense'} '
              'of ${_money.format(result.amount)} recorded.',
        );
      } catch (_) {
        // A notification failure should not undo a saved transaction.
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            item == null
                ? 'Transaction added successfully.'
                : 'Transaction updated successfully.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save transaction: $e'),
        ),
      );
    }
  }

  Future<void> _delete(TransactionEntry item) async {
    if (item.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: const Text(
          'This transaction will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _repo.deleteTransaction(item.id!);

      if (!mounted) return;

      setState(_reload);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction deleted.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not delete transaction: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            tooltip: 'Add transaction',
            onPressed: () => _add(),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(),
        icon: const Icon(Icons.add),
        label: const Text('Add transaction'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search transactions',
                suffixIcon: _search.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _search = '';
                            _reload();
                          });
                        },
                        icon: const Icon(Icons.close),
                      ),
              ),
              onChanged: (value) {
                setState(() {
                  _search = value;
                  _reload();
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment<String>(
                    value: 'all',
                    label: Text('All'),
                  ),
                  ButtonSegment<String>(
                    value: 'income',
                    label: Text('Income'),
                  ),
                  ButtonSegment<String>(
                    value: 'expense',
                    label: Text('Expenses'),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (selection) {
                  setState(() {
                    _type = selection.first;
                    _reload();
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: FutureBuilder<List<TransactionEntry>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 40,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Could not load transactions.',
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton(
                            onPressed: () {
                              setState(_reload);
                            },
                            child: const Text('Try again'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final items = snapshot.data ?? [];

                if (items.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.receipt_long_outlined,
                            size: 44,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _search.isNotEmpty
                                ? 'No matching transactions found.'
                                : 'No transactions yet.',
                            style: theme.textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Add an income or expense to get started.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () => _add(),
                            icon: const Icon(Icons.add),
                            label: const Text('Add transaction'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    8,
                    16,
                    100,
                  ),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final transaction = items[index];
                    final isIncome = transaction.type == 'income';

                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: isIncome
                              ? Colors.green.withValues(alpha: 0.12)
                              : theme.colorScheme.errorContainer,
                          child: Icon(
                            isIncome ? Icons.south_west : Icons.north_east,
                            color: isIncome
                                ? Colors.green
                                : theme.colorScheme.error,
                          ),
                        ),
                        title: Text(
                          transaction.category,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Text(
                            '${DateFormat.yMMMd().add_jm().format(transaction.date)}\n'
                            '${transaction.paymentMethod}'
                            '${transaction.notes.isEmpty ? '' : '\n${transaction.notes}'}'
                            '${transaction.recurring ? '\nRecurring' : ''}',
                          ),
                        ),
                        isThreeLine: true,
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${isIncome ? '+' : '-'}'
                              '${_money.format(transaction.amount)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isIncome
                                    ? Colors.green
                                    : theme.colorScheme.error,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Icon(
                              Icons.edit_outlined,
                              size: 16,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                        onTap: () => _add(item: transaction),
                        onLongPress: () => _delete(transaction),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class TransactionForm extends StatefulWidget {
  final TransactionEntry? item;

  const TransactionForm({
    super.key,
    this.item,
  });

  @override
  State<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late String _type;
  late String _category;
  late String _method;
  late DateTime _date;

  final TextEditingController _amountController = TextEditingController();

  final TextEditingController _notesController = TextEditingController();

  bool _recurring = false;

  final List<String> _expenseCategories = [
    'Food',
    'Transportation',
    'Bills',
    'Shopping',
    'Health',
    'Education',
    'Entertainment',
    'Savings',
    'Other',
  ];

  final List<String> _incomeCategories = [
    'Salary',
    'Business',
    'Allowance',
    'Other Income',
  ];

  List<String> get _availableCategories =>
      _type == 'income' ? _incomeCategories : _expenseCategories;

  @override
  void initState() {
    super.initState();

    final transaction = widget.item;

    _type = transaction?.type ?? 'expense';
    _category = transaction?.category ?? 'Food';
    _method = transaction?.paymentMethod ?? 'Cash';
    _date = transaction?.date ?? DateTime.now();
    _recurring = transaction?.recurring ?? false;

    _amountController.text =
        transaction == null ? '' : transaction.amount.toString();

    _notesController.text = transaction?.notes ?? '';

    if (!_availableCategories.contains(_category)) {
      _category = _availableCategories.first;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (selectedDate == null || !mounted) return;

    setState(() {
      _date = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        _date.hour,
        _date.minute,
      );
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(
      _amountController.text.trim(),
    );

    if (amount == null || !amount.isFinite || amount <= 0) {
      return;
    }

    final transaction = TransactionEntry(
      id: widget.item?.id,
      type: _type,
      amount: amount,
      category: _category,
      date: _date,
      paymentMethod: _method,
      notes: _notesController.text.trim(),
      recurring: _recurring,
    );

    Navigator.of(context).pop(transaction);
  }

  @override
  Widget build(BuildContext context) {
    final categories = _availableCategories;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.item == null ? 'Add transaction' : 'Edit transaction',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment<String>(
                    value: 'expense',
                    label: Text('Expense'),
                    icon: Icon(Icons.north_east),
                  ),
                  ButtonSegment<String>(
                    value: 'income',
                    label: Text('Income'),
                    icon: Icon(Icons.south_west),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (selection) {
                  setState(() {
                    _type = selection.first;

                    if (!categories.contains(_category)) {
                      _category = _availableCategories.first;
                    } else {
                      _category = _availableCategories.first;
                    }
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '₱ ',
                  helperText: 'Enter an amount greater than zero',
                ),
                validator: (value) {
                  final amount = double.tryParse(
                    (value ?? '').trim(),
                  );

                  if (amount == null || !amount.isFinite || amount <= 0) {
                    return 'Enter a valid amount greater than zero';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _category,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Category',
                ),
                items: categories
                    .map(
                      (category) => DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    _category = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _method,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Payment method',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Cash',
                    child: Text('Cash'),
                  ),
                  DropdownMenuItem(
                    value: 'Bank transfer',
                    child: Text('Bank transfer'),
                  ),
                  DropdownMenuItem(
                    value: 'Debit card',
                    child: Text('Debit card'),
                  ),
                  DropdownMenuItem(
                    value: 'Credit card',
                    child: Text('Credit card'),
                  ),
                  DropdownMenuItem(
                    value: 'E-wallet',
                    child: Text('E-wallet'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    _method = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _selectDate,
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(
                    DateFormat.yMMMd().add_jm().format(_date),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                minLines: 1,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  hintText: 'Optional transaction details',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Recurring transaction'),
                subtitle: const Text(
                  'Mark this transaction as recurring',
                ),
                value: _recurring,
                onChanged: (value) {
                  setState(() {
                    _recurring = value ?? false;
                  });
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Text('Save transaction'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
