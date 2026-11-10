import 'package:decimal/decimal.dart';
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

/// Navy hero card on Home: total net worth that counts up on load, a one-time
/// light sheen, and a per-currency breakdown when the user holds several.
class NetWorthCard extends ConsumerWidget {
  const NetWorthCard({super.key});

  static const int _maxBreakdownChips = 3;

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

        return _TiltIn(
          child: Container(
            decoration: AppDecorations.heroCard(),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                const Positioned.fill(child: _Sheen()),
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Net worth',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.onNavyMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.silver,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              netWorth.total.currency.value,
                              key: const Key('net-worth-currency'),
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: AppColors.navy,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _CountUpAmount(
                        key: const Key('net-worth-total'),
                        amount: netWorth.total.amount,
                        currencyCode: netWorth.total.currency.value,
                      ),
                      if (hasMultipleCurrencies) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            for (final entry in netWorth.walletBreakdown
                                .take(_maxBreakdownChips)) ...[
                              Expanded(child: _BreakdownChip(entry: entry)),
                              if (entry !=
                                  netWorth.walletBreakdown
                                      .take(_maxBreakdownChips)
                                      .last)
                                const SizedBox(width: 8),
                            ],
                          ],
                        ),
                      ],
                      ratesUpdatedAsync.when(
                        data: (updatedAt) {
                          if (updatedAt == null || !hasMultipleCurrencies) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 14),
                            child: Text(
                              ExchangeRateLabels.lastUpdated(
                                updatedAt,
                                DateTime.now(),
                              ),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.onNavyMuted,
                                letterSpacing: 0,
                                fontSize: 12,
                              ),
                            ),
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, _) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
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

/// Counts from zero to [amount] once. Money stays [Decimal]; only the
/// animation progress is a double, and the final frame shows the exact value.
class _CountUpAmount extends StatelessWidget {
  const _CountUpAmount({
    required this.amount,
    required this.currencyCode,
    super.key,
  });

  final Decimal amount;
  final String currencyCode;

  static const int _progressDigits = 3;

  @override
  Widget build(BuildContext context) {
    final duration = AppMotion.resolve(context, AppMotion.countUp);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, progress, _) {
        final shown = progress >= 1
            ? amount
            : (amount * Decimal.parse(progress.toStringAsFixed(_progressDigits)))
                .round(scale: 2);
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            MoneyDisplay.withCurrency(
              amount: shown.toString(),
              currencyCode: currencyCode,
            ),
            semanticsLabel: MoneyDisplay.withCurrency(
              amount: amount.toString(),
              currencyCode: currencyCode,
            ),
            style: AppTypography.money(
              fontSize: 40,
              color: AppColors.onPrimary,
            ),
          ),
        );
      },
    );
  }
}

class _BreakdownChip extends StatelessWidget {
  const _BreakdownChip({required this.entry});

  final ConvertedWalletBalance entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.navyRaised,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.wallet.currencyCode,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.onNavyMuted,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              MoneyDisplay.formatAmount(entry.wallet.balance),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Card tilts up from a slight 3D angle the first time it appears.
class _TiltIn extends StatelessWidget {
  const _TiltIn({required this.child});

  final Widget child;

  static const double _startTiltRadians = 0.32;
  static const double _perspective = 0.0012;
  static const Duration _duration = Duration(milliseconds: 800);

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.resolve(context, _duration),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, t, child) {
        final matrix = Matrix4.identity()
          ..setEntry(3, 2, _perspective)
          ..rotateX(_startTiltRadians * (1 - t));
        return Opacity(
          opacity: t,
          child: Transform(
            alignment: Alignment.bottomCenter,
            transform: matrix,
            child: child,
          ),
        );
      },
    );
  }
}

/// A soft band of light that sweeps across the card once.
class _Sheen extends StatelessWidget {
  const _Sheen();

  static const Duration _duration = Duration(milliseconds: 1400);
  static const double _bandWidthFactor = 0.25;
  static const double _bandAlpha = 0.08;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: -0.4, end: 1.4),
        duration: _duration,
        curve: Curves.easeInOut,
        builder: (context, t, _) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              return Stack(
                children: [
                  Positioned(
                    left: width * t,
                    top: -20,
                    bottom: -20,
                    width: width * _bandWidthFactor,
                    child: Transform.rotate(
                      angle: 0.35,
                      child: ColoredBox(
                        color: Colors.white.withValues(alpha: _bandAlpha),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
