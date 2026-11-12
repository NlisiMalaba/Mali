import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mali_app/application/providers/home_providers.dart';
import 'package:mali_app/domain/usecases/calculate_net_worth_usecase.dart';
import 'package:mali_app/domain/value_objects/money.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/theme/app_decorations.dart';
import 'package:mali_app/presentation/theme/app_motion.dart';
import 'package:mali_app/presentation/theme/app_typography.dart';
import 'package:mali_app/presentation/utils/money_display.dart';
import 'package:mali_app/presentation/widgets/common/shimmer_box.dart';
import 'package:mali_app/presentation/widgets/common/currency_flag_badge.dart';

/// Navy hero card on Home: per-currency net worth (never FX-mixed), a one-time
/// light sheen, sparkline, and per-wallet chips.
class NetWorthCard extends ConsumerWidget {
  const NetWorthCard({super.key});

  static const int _maxBreakdownChips = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final netWorthAsync = ref.watch(homeNetWorthProvider);
    final summaryAsync = ref.watch(homeMonthlySummaryDisplayProvider);

    return netWorthAsync.when(
      loading: () => const NetWorthCardSkeleton(),
      error: (error, _) => Text('Could not load net worth: $error'),
      data: (netWorth) {
        final totals = netWorth.totalsByCurrency;
        final monthDelta = summaryAsync.asData?.value;
        final badgeCurrency = monthDelta?.displayCurrency.value;

        return _TiltIn(
          child: Container(
            decoration: AppDecorations.heroCard(),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                const Positioned.fill(child: _Sheen()),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  GoRouter.maybeOf(context)?.push('/wallets'),
                              child: Text(
                                'Net worth ›',
                                key: const Key('net-worth-currency'),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.onNavyMuted,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          if (monthDelta != null && badgeCurrency != null)
                            _MonthDeltaBadge(
                              net: monthDelta.net,
                              currencyCode: badgeCurrency,
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (totals.isEmpty)
                        Text(
                          MoneyDisplay.compact(
                            amount: '0',
                            currencyCode: 'USD',
                          ),
                          key: const Key('net-worth-total'),
                          style: AppTypography.money(
                            fontSize: 44,
                            color: AppColors.onPrimary,
                          ),
                        )
                      else if (totals.length == 1)
                        _CountUpAmount(
                          key: const Key('net-worth-total'),
                          amount: totals.first.amount,
                          currencyCode: totals.first.currency.value,
                        )
                      else
                        KeyedSubtree(
                          key: const Key('net-worth-total'),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (var i = 0; i < totals.length; i++) ...[
                                if (i > 0) const SizedBox(height: 6),
                                _CurrencyTotalRow(total: totals[i]),
                              ],
                            ],
                          ),
                        ),
                      const SizedBox(height: 8),
                      const SizedBox(
                        height: 40,
                        width: double.infinity,
                        child: _Sparkline(),
                      ),
                      if (netWorth.walletBreakdown.isNotEmpty) ...[
                        const SizedBox(height: 12),
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
}

class _CurrencyTotalRow extends StatelessWidget {
  const _CurrencyTotalRow({required this.total});

  final Money total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final code = total.currency.value;
    return Row(
      children: [
        CurrencyFlag(code, size: 16),
        const SizedBox(width: 8),
        Text(
          code,
          style: theme.textTheme.labelMedium?.copyWith(
            color: AppColors.onNavyMuted,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              MoneyDisplay.compact(
                amount: total.amount.toString(),
                currencyCode: code,
              ),
              style: AppTypography.money(
                fontSize: 28,
                color: AppColors.onPrimary,
              ),
            ),
          ),
        ),
      ],
    );
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
            MoneyDisplay.compact(
              amount: shown.toString(),
              currencyCode: currencyCode,
            ),
            semanticsLabel: MoneyDisplay.compact(
              amount: amount.toString(),
              currencyCode: currencyCode,
            ),
            style: AppTypography.money(
              fontSize: 44,
              color: AppColors.onPrimary,
            ),
          ),
        );
      },
    );
  }
}

class _MonthDeltaBadge extends StatelessWidget {
  const _MonthDeltaBadge({
    required this.net,
    required this.currencyCode,
  });

  final Decimal net;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPositive = net >= Decimal.zero;
    final prefix = isPositive ? '+' : '−';
    final absolute = net.abs();
    final label =
        '$prefix${MoneyDisplay.compact(amount: absolute.toString(), currencyCode: currencyCode)} this month';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.silver,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: AppColors.navy,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _BreakdownChip extends StatelessWidget {
  const _BreakdownChip({required this.entry});

  final WalletBalanceBreakdown entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.navyRaised,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CurrencyFlag(entry.wallet.currencyCode, size: 13),
              const SizedBox(width: 5),
              Text(
                entry.wallet.currencyCode,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.onNavyMuted,
                  letterSpacing: 0.6,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              MoneyDisplay.compact(
                amount: entry.wallet.balance,
                currencyCode: entry.wallet.currencyCode,
                trimTrailingZeros: true,
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.onPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Sparkline extends StatelessWidget {
  const _Sparkline();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SparklinePainter(color: AppColors.silver),
      size: Size.infinite,
    );
  }
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(0, size.height * 0.85)
      ..cubicTo(
        size.width * 0.15,
        size.height * 0.8,
        size.width * 0.25,
        size.height * 0.65,
        size.width * 0.35,
        size.height * 0.68,
      )
      ..cubicTo(
        size.width * 0.5,
        size.height * 0.72,
        size.width * 0.55,
        size.height * 0.35,
        size.width * 0.68,
        size.height * 0.42,
      )
      ..cubicTo(
        size.width * 0.8,
        size.height * 0.48,
        size.width * 0.88,
        size.height * 0.18,
        size.width,
        size.height * 0.12,
      );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.color != color;
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
