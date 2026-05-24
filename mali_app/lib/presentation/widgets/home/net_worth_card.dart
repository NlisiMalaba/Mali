import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mali_app/application/providers/home_providers.dart';
import 'package:mali_app/domain/usecases/calculate_net_worth_usecase.dart';
import 'package:mali_app/domain/value_objects/currency_code.dart';
import 'package:mali_app/presentation/utils/currency_display.dart';
import 'package:mali_app/presentation/utils/exchange_rate_labels.dart';
import 'package:mali_app/presentation/utils/money_display.dart';

class NetWorthCard extends ConsumerWidget {
  const NetWorthCard({super.key});

  static const double _walletRowHeight = 72;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final netWorthAsync = ref.watch(homeNetWorthProvider);
    final ratesUpdatedAsync = ref.watch(exchangeRatesLastUpdatedProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: netWorthAsync.when(
          loading: () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Net worth',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: CircularProgressIndicator(),
                ),
              ),
            ],
          ),
          error: (error, _) => Text('Could not load net worth: $error'),
          data: (netWorth) {
            final hasMultipleCurrencies = _hasMultipleCurrencies(
              netWorth.walletBreakdown,
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Net worth',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  MoneyDisplay.withCurrency(
                    amount: netWorth.total.amount.toString(),
                    currencyCode: netWorth.total.currency.value,
                  ),
                  key: const Key('net-worth-total'),
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                if (netWorth.walletBreakdown.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _WalletBalancesRow(
                    breakdown: netWorth.walletBreakdown,
                  ),
                ],
                ratesUpdatedAsync.when(
                  data: (updatedAt) {
                    if (updatedAt == null || !hasMultipleCurrencies) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        ExchangeRateLabels.lastUpdated(
                          updatedAt,
                          DateTime.now(),
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  bool _hasMultipleCurrencies(List<ConvertedWalletBalance> breakdown) {
    if (breakdown.length <= 1) {
      return false;
    }
    final currencies = breakdown
        .map((entry) => entry.wallet.currencyCode)
        .toSet();
    return currencies.length > 1;
  }
}

class _WalletBalancesRow extends StatelessWidget {
  const _WalletBalancesRow({
    required this.breakdown,
  });

  final List<ConvertedWalletBalance> breakdown;

  @override
  Widget build(BuildContext context) {
    if (breakdown.length <= 3) {
      return Row(
        children: [
          for (var index = 0; index < breakdown.length; index++) ...[
            if (index > 0) const SizedBox(width: 12),
            Expanded(
              child: _WalletBalanceItem(entry: breakdown[index]),
            ),
          ],
        ],
      );
    }

    return SizedBox(
      height: NetWorthCard._walletRowHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: breakdown.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return SizedBox(
            width: 96,
            child: _WalletBalanceItem(entry: breakdown[index]),
          );
        },
      ),
    );
  }
}

class _WalletBalanceItem extends StatelessWidget {
  const _WalletBalanceItem({
    required this.entry,
  });

  final ConvertedWalletBalance entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = CurrencyCode(entry.wallet.currencyCode);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          CurrencyDisplay.flagEmoji(currency),
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 6),
        Text(
          MoneyDisplay.withCurrency(
            amount: entry.wallet.balance,
            currencyCode: currency.value,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          entry.wallet.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
