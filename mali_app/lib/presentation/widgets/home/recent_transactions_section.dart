import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mali_app/application/providers/home_providers.dart';
import 'package:mali_app/presentation/widgets/transaction/transaction_tile.dart';

class RecentTransactionsSection extends ConsumerWidget {
  const RecentTransactionsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(homeRecentTransactionsProvider);
    final theme = Theme.of(context);

    return transactionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Text('Could not load transactions: $error'),
      data: (transactions) {
        if (transactions.isEmpty) {
          return Text(
            'No transactions yet.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
            ),
          );
        }

        return Column(
          children: [
            for (var index = 0; index < transactions.length; index++) ...[
              if (index > 0) const Divider(height: 1),
              TransactionTile(transaction: transactions[index]),
            ],
          ],
        );
      },
    );
  }
}
