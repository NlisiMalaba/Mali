import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mali_app/application/providers/budget_providers.dart';
import 'package:mali_app/presentation/widgets/budget/add_budget_sheet.dart';
import 'package:mali_app/presentation/widgets/budget/budget_list_tile.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  static const Key screenKey = Key('budgets-screen');

  Future<void> _openAddBudget(BuildContext context) async {
    final created = await AddBudgetSheet.show(context);
    if (created == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Budget added.')),
      );
    }
  }

  String _monthTitle() {
    return DateFormat.yMMMM().format(DateTime.now());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(currentMonthBudgetsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      key: screenKey,
      appBar: AppBar(
        title: Text('Budgets · ${_monthTitle()}'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddBudget(context),
        tooltip: 'Add budget',
        child: const Icon(Icons.add),
      ),
      body: budgetsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Could not load budgets: $error'),
          ),
        ),
        data: (budgets) {
          if (budgets.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'No budgets for ${_monthTitle()}',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create a budget to track spending by category.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () => _openAddBudget(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Add your first budget'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            itemCount: budgets.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return BudgetListTile(budget: budgets[index]);
            },
          );
        },
      ),
    );
  }
}
