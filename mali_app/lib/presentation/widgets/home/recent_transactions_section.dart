import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mali_app/application/providers/home_providers.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/widgets/transaction/transaction_tile.dart';

class RecentTransactionsSection extends ConsumerWidget {
  const RecentTransactionsSection({
    this.maxItems,
    super.key,
  });

  final int? maxItems;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(homeRecentTransactionsProvider);
    final theme = Theme.of(context);

    return transactionsAsync.when(
      loading: () => const SizedBox(
        height: 48,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (error, _) => Text('Could not load transactions: $error'),
      data: (transactions) {
        if (transactions.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'No transactions yet.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          );
        }

        final visible = maxItems == null
            ? transactions
            : transactions.take(maxItems!).toList();

        return Column(
          children: [
            for (final transaction in visible)
              TransactionTile(
                transaction: transaction,
                compact: true,
              ),
          ],
        );
      },
    );
  }
}
