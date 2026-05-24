import 'package:flutter/material.dart';
import 'package:mali_app/presentation/widgets/transaction/add_transaction_sheet.dart';

/// Route host for the add-transaction flow.
class AddTransactionScreen extends StatelessWidget {
  const AddTransactionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Transaction')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AddTransactionSheet.show(context),
        icon: const Icon(Icons.add),
        label: const Text('New transaction'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Tap the button to log a new expense, income, or transfer.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
