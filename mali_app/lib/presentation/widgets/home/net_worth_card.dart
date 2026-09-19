import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mali_app/application/providers/home_providers.dart';
import 'package:mali_app/domain/usecases/calculate_net_worth_usecase.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/theme/app_decorations.dart';
import 'package:mali_app/presentation/theme/app_motion.dart';
import 'package:mali_app/presentation/theme/app_typography.dart';
import 'package:mali_app/presentation/utils/exchange_rate_labels.dart';
import 'package:mali_app/presentation/utils/money_display.dart';
import 'package:mali_app/presentation/widgets/common/shimmer_box.dart';

class NetWorthCard extends ConsumerWidget {
  const NetWorthCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final netWorthAsync = ref.watch(homeNetWorthProvider);
    final ratesUpdatedAsync = ref.watch(exchangeRatesLastUpdatedProvider);

    return netWorthAsync.when(
      loading: () => const NetWorthCardSkeleton(),
      error: (error, _) => Text('Could not load net worth: $error'),
      data: (netWorth) {
        final hasMultipleCurrencies = _hasMultipleCurrencies(
          netWorth.walletBreakdown,
        );

        return AnimatedSwitcher(
            duration: AppMotion.resolve(context, AppMotion.normal),
            switchInCurve: AppMotion.standard,
            child: Container(
              key: ValueKey(netWorth.total.amount.toString()),
              decoration: AppDecorations.heroCard(),
              padding: const EdgeInsets.all(32),
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Icon(
                      Icons.account_balance,
                      size: 72,
                      color: AppColors.onPrimaryContainer.withValues(alpha: 0.2),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOTAL EST. VALUE',
                        style: AppTypography.sectionLabel(context).copyWith(
                          color: AppColors.onPrimaryContainer.withValues(
                            alpha: 0.8,
                          ),
                          fontSize: 11,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            MoneyDisplay.withCurrency(
                              amount: netWorth.total.amount.toString(),
                              currencyCode: netWorth.total.currency.value,
                            ),
                            key: const Key('net-worth-total'),
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.onPrimaryContainer,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            netWorth.total.currency.value,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.onPrimaryContainer.withValues(
                                alpha: 0.7,
                              ),
                            ),
                          ),
                        ],
                      ),
                      ratesUpdatedAsync.when(
                        data: (updatedAt) {
                          if (updatedAt == null || !hasMultipleCurrencies) {
                            return const SizedBox(height: 24);
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 24),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.onPrimaryContainer.withValues(
                                  alpha: 0.2,
                                ),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                ExchangeRateLabels.lastUpdated(
                                  updatedAt,
                                  DateTime.now(),
                                ),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: AppColors.onPrimaryContainer,
                                ),
                              ),
                            ),
                          );
                        },
                        loading: () => const SizedBox(height: 24),
                        error: (_, __) => const SizedBox(height: 24),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        );
      },
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
