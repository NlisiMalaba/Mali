import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mali_app/application/providers/wallet_providers.dart';
import 'package:mali_app/domain/value_objects/currency_code.dart';
import 'package:mali_app/presentation/utils/currency_display.dart';
import 'package:mali_app/presentation/utils/money_display.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/widgets/transaction/add_transaction_sheet.dart';

class WalletTransactionsScreen extends ConsumerWidget {
  const WalletTransactionsScreen({
    required this.walletId,
    super.key,
  });

  final String walletId;

  Color _amountColor(String type) {
    return switch (type) {
      'income' => AppColors.success,
      'expense' => AppColors.error,
      _ => AppColors.tealPrimary,
    };
  }

  String _amountPrefix(String type) {
    return switch (type) {
      'income' => '+',
      'expense' => '-',
      _ => '',
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(walletByIdProvider(walletId));
    final transactionsAsync = ref.watch(walletTransactionsProvider(walletId));
    final theme = Theme.of(context);
    final dateFormat = DateFormat.MMMd().add_jm();

    return Scaffold(
      appBar: AppBar(
        title: walletAsync.when(
          data: (wallet) => Text(wallet?.name ?? 'Wallet'),
          loading: () => const Text('Wallet'),
          error: (_, __) => const Text('Wallet'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => AddTransactionSheet.show(
          context,
          initialWalletId: walletId,
        ),
        tooltip: 'Add transaction',
        child: const Icon(Icons.add),
      ),
      body: transactionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Could not load transactions: $error'),
          ),
        ),
        data: (transactions) {
          if (transactions.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No transactions yet.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: transactions.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              final currency = CurrencyCode(transaction.currencyCode);

              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(transaction.title),
                subtitle: Text(dateFormat.format(transaction.transactionDate)),
                trailing: Text(
                  '${_amountPrefix(transaction.type)}'
                  '${MoneyDisplay.withCurrency(
                    amount: transaction.amount,
                    currencyCode: transaction.currencyCode,
                  )}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: _amountColor(transaction.type),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                leading: CircleAvatar(
                  backgroundColor:
                      theme.colorScheme.surfaceContainerHighest,
                  child: Text(CurrencyDisplay.flagEmoji(currency)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
