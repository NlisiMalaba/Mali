import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mali_app/application/models/home_monthly_summary_display.dart';
import 'package:mali_app/application/providers/display_currency_provider.dart';
import 'package:mali_app/application/providers/home_providers.dart';
import 'package:mali_app/application/providers/use_case_providers.dart';
import 'package:mali_app/application/providers/wallet_card_providers.dart';
import 'package:mali_app/application/providers/wallet_providers.dart';
import 'package:mali_app/domain/entities/transaction.dart';
import 'package:mali_app/domain/entities/wallet.dart';
import 'package:mali_app/domain/usecases/calculate_net_worth_usecase.dart';
import 'package:mali_app/domain/value_objects/currency_code.dart';
import 'package:mali_app/domain/value_objects/money.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/theme/app_typography.dart';
import 'package:mali_app/presentation/utils/money_display.dart';
import 'package:mali_app/presentation/widgets/common/currency_flag_badge.dart';
import 'package:mali_app/presentation/widgets/common/fade_slide_in.dart';
import 'package:mali_app/presentation/widgets/common/pressable_scale.dart';
import 'package:mali_app/presentation/widgets/transaction/add_transaction_sheet.dart';
import 'package:mali_app/presentation/widgets/transaction/transaction_type_toggle.dart';
import 'package:mali_app/presentation/widgets/wallet/add_wallet_sheet.dart';

class WalletsScreen extends ConsumerWidget {
  const WalletsScreen({super.key});

  Future<void> _openAddWallet(BuildContext context) async {
    final created = await AddWalletSheet.show(context);
    if (created == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wallet added.')),
      );
    }
  }

  Future<bool> _archiveWallet(
    BuildContext context,
    WidgetRef ref,
    Wallet wallet,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive wallet?'),
        content: Text(
          '${wallet.name} will be hidden from your active wallets.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );
    if (confirmed != true) return false;

    final result = await ref.read(archiveWalletUseCaseProvider)(
      walletId: wallet.id,
    );
    if (!context.mounted) return false;

    final failure = result.fold((left) => left, (_) => null);
    if (failure != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message)),
      );
      return false;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${wallet.name} archived.')),
    );
    return true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletsAsync = ref.watch(activeWalletsProvider);
    final summaryAsync = ref.watch(homeMonthlySummaryDisplayProvider);
    final netWorthAsync = ref.watch(homeNetWorthProvider);
    final displayCurrency = ref.watch(displayCurrencyProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: walletsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Error: $error')),
          data: (wallets) {
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: FadeSlideIn(
                      index: 0,
                      child: Row(
                        children: [
                          _HeaderIconButton(
                            icon: Icons.chevron_left_rounded,
                            onPressed: () {
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                context.go('/');
                              }
                            },
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Wallets',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 28,
                                letterSpacing: -0.6,
                                color: AppColors.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  sliver: SliverToBoxAdapter(
                    child: FadeSlideIn(
                      index: 1,
                      child: _WalletsSummary(
                        netWorthAsync: netWorthAsync,
                        summaryAsync: summaryAsync,
                        displayCurrency: displayCurrency,
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      mainAxisExtent: 196,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == wallets.length) {
                          return FadeSlideIn(
                            index: index + 2,
                            child: _AddWalletTile(
                              onTap: () => _openAddWallet(context),
                            ),
                          );
                        }

                        final wallet = wallets[index];
                        return FadeSlideIn(
                          index: index + 2,
                          child: Dismissible(
                            key: ValueKey(wallet.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 16),
                              decoration: BoxDecoration(
                                color: AppColors.errorContainer,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: const Icon(Icons.archive_outlined),
                            ),
                            confirmDismiss: (_) =>
                                _archiveWallet(context, ref, wallet),
                            child: _WalletGridCard(
                              wallet: wallet,
                              variant: _WalletCardVariant.forIndex(index),
                              onTap: () =>
                                  context.push('/wallets/${wallet.id}'),
                            ),
                          ),
                        );
                      },
                      childCount: wallets.length + 1,
                    ),
                  ),
                ),
                if (wallets.length >= 2)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: FadeSlideIn(
                        index: wallets.length + 3,
                        child: _MoveBetweenWalletsTile(
                          onTap: () => AddTransactionSheet.show(
                            context,
                            initialType: TransactionType.transfer,
                            initialWalletId: wallets.first.id,
                          ),
                        ),
                      ),
                    ),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                  sliver: SliverToBoxAdapter(
                    child: FadeSlideIn(
                      index: wallets.length + 4,
                      child: Text(
                        'Tap a wallet to open it · bars show this month: '
                        'green in, red out',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 12.5,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

enum _WalletCardVariant {
  silver,
  navy,
  light;

  static _WalletCardVariant forIndex(int index) {
    switch (index % 3) {
      case 0:
        return _WalletCardVariant.silver;
      case 1:
        return _WalletCardVariant.navy;
      default:
        return _WalletCardVariant.light;
    }
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE1E5EE), width: 0.8),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: AppColors.onSurface, size: 22),
        ),
      ),
    );
  }
}

class _WalletsSummary extends StatelessWidget {
  const _WalletsSummary({
    required this.netWorthAsync,
    required this.summaryAsync,
    required this.displayCurrency,
  });

  final AsyncValue<CalculateNetWorthResult> netWorthAsync;
  final AsyncValue<HomeMonthlySummaryDisplay> summaryAsync;
  final CurrencyCode displayCurrency;

  Money? _primaryTotal(CalculateNetWorthResult netWorth) {
    return netWorth.totalFor(displayCurrency) ??
        (netWorth.totalsByCurrency.isEmpty
            ? null
            : netWorth.totalsByCurrency.first);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: netWorthAsync.when(
            loading: () => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All wallets in ${displayCurrency.value}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ),
            error: (_, _) => Text(
              'Could not load totals',
              style: theme.textTheme.bodySmall,
            ),
            data: (netWorth) {
              final total = _primaryTotal(netWorth);
              final currency = total?.currency ?? displayCurrency;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'All wallets in ${currency.value}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    total == null
                        ? MoneyDisplay.compact(
                            amount: '0',
                            currencyCode: currency.value,
                          )
                        : MoneyDisplay.compact(
                            amount: total.amount.toString(),
                            currencyCode: total.currency.value,
                          ),
                    style: AppTypography.money(
                      fontSize: 34,
                      color: AppColors.onSurface,
                    ).copyWith(letterSpacing: -1.2),
                  ),
                ],
              );
            },
          ),
        ),
        summaryAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
          data: (summary) {
            final net = summary.net;
            final positive = net >= Decimal.zero;
            final label = MoneyDisplay.compactSigned(
              amount: net.abs().toString(),
              currencyCode: summary.displayCurrency.value,
              prefix: positive ? '+' : '\u2212',
            );
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '$label this month',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: positive ? AppColors.income : AppColors.expense,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _WalletGridCard extends ConsumerWidget {
  const _WalletGridCard({
    required this.wallet,
    required this.variant,
    required this.onTap,
  });

  final Wallet wallet;
  final _WalletCardVariant variant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final equivalentAsync = ref.watch(
      walletEquivalentLabelProvider((
        balance: wallet.balance,
        currencyCode: wallet.currencyCode,
      )),
    );
    final txAsync = ref.watch(walletTransactionsProvider(wallet.id));
    final flow = _monthFlow(txAsync.asData?.value ?? const []);

    final background = switch (variant) {
      _WalletCardVariant.silver => AppColors.silver,
      _WalletCardVariant.navy => AppColors.navy,
      _WalletCardVariant.light => AppColors.surfaceContainerLowest,
    };
    final foreground = switch (variant) {
      _WalletCardVariant.navy => AppColors.onPrimary,
      _ => AppColors.navy,
    };
    final muted = foreground.withValues(alpha: 0.75);
    final incomeBar = switch (variant) {
      _WalletCardVariant.navy => const Color(0xFF5FD394),
      _ => AppColors.income,
    };
    final expenseBar = switch (variant) {
      _WalletCardVariant.navy => const Color(0xFFFF8A7D),
      _ => AppColors.expense,
    };
    final subtitle = equivalentAsync.asData?.value ??
        _walletSubtitle(wallet.name);

    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(24),
          border: variant == _WalletCardVariant.navy
              ? null
              : Border.all(color: const Color(0xFFD4DAE6), width: 0.8),
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withValues(alpha: 0.45),
              blurRadius: 22,
              offset: const Offset(0, 10),
              spreadRadius: -16,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: foreground.withValues(alpha: 0.14),
                        blurRadius: 0,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: CurrencyFlag(wallet.currencyCode, size: 34),
                  ),
                ),
                const Spacer(),
                Text(
                  wallet.currencyCode,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: muted,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              wallet.name,
              style: theme.textTheme.titleSmall?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              MoneyDisplay.compact(
                amount: wallet.balance,
                currencyCode: wallet.currencyCode,
                trimTrailingZeros: wallet.currencyCode == 'ZWG',
              ),
              style: AppTypography.money(
                fontSize: 22,
                color: foreground,
              ).copyWith(letterSpacing: -0.6),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: muted,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            _MonthFlowBar(
              income: flow.income,
              expenses: flow.expenses,
              incomeColor: incomeBar,
              expenseColor: expenseBar,
              dimIncome: flow.income <= Decimal.zero,
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  MoneyDisplay.compactSigned(
                    amount: flow.income.toString(),
                    currencyCode: wallet.currencyCode,
                    prefix: '+',
                  ),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: incomeBar,
                    fontWeight: FontWeight.w600,
                    fontSize: 11.5,
                  ),
                ),
                Text(
                  MoneyDisplay.compactSigned(
                    amount: flow.expenses.toString(),
                    currencyCode: wallet.currencyCode,
                    prefix: '\u2212',
                  ),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: expenseBar,
                    fontWeight: FontWeight.w600,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthFlowBar extends StatelessWidget {
  const _MonthFlowBar({
    required this.income,
    required this.expenses,
    required this.incomeColor,
    required this.expenseColor,
    this.dimIncome = false,
  });

  final Decimal income;
  final Decimal expenses;
  final Color incomeColor;
  final Color expenseColor;
  final bool dimIncome;

  @override
  Widget build(BuildContext context) {
    final total = income + expenses;
    final incomeShare = total <= Decimal.zero
        ? 0.5
        : (income / total).toDouble();
    final incomeFlex = (incomeShare * 100).round().clamp(1, 99);
    final expenseFlex = 100 - incomeFlex;

    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: SizedBox(
        height: 6,
        child: Row(
          children: [
            Expanded(
              flex: incomeFlex,
              child: ColoredBox(
                color: dimIncome
                    ? incomeColor.withValues(alpha: 0.35)
                    : incomeColor,
              ),
            ),
            const SizedBox(width: 2),
            Expanded(
              flex: expenseFlex,
              child: ColoredBox(color: expenseColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddWalletTile extends StatelessWidget {
  const _AddWalletTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PressableScale(
      onTap: onTap,
      child: CustomPaint(
        painter: _DashedRRectPainter(
          color: const Color(0xFFC3CBDB),
          radius: 24,
          strokeWidth: 1.6,
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.navy,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add,
                    color: AppColors.silver,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Add wallet',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Bank, mobile money or cash',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  _DashedRRectPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
  });

  final Color color;
  final double radius;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(radius),
        ),
      );

    const dashWidth = 6.0;
    const dashSpace = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.radius != radius ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

class _MoveBetweenWalletsTile extends StatelessWidget {
  const _MoveBetweenWalletsTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFECEFF5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.swap_horiz_rounded,
                color: AppColors.navy,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Move between wallets',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    'Cash to EcoCash, Rand to USD…',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

({Decimal income, Decimal expenses}) _monthFlow(List<Transaction> transactions) {
  final now = DateTime.now();
  var income = Decimal.zero;
  var expenses = Decimal.zero;

  for (final tx in transactions) {
    if (tx.deletedAt != null) continue;
    final date = tx.transactionDate;
    if (date.year != now.year || date.month != now.month) continue;

    final amount = Decimal.tryParse(tx.amount) ?? Decimal.zero;
    switch (tx.type) {
      case 'income':
        income += amount;
      case 'expense':
        expenses += amount;
      case 'transfer':
        expenses += amount;
      default:
        break;
    }
  }

  return (income: income, expenses: expenses);
}

String _walletSubtitle(String name) {
  final lower = name.toLowerCase();
  if (lower.contains('ecocash') || lower.contains('onemoney')) {
    return 'Mobile money';
  }
  if (lower.contains('bank')) {
    return 'Bank account';
  }
  if (lower.contains('cash')) {
    return 'Main wallet';
  }
  return 'Digital wallet';
}
