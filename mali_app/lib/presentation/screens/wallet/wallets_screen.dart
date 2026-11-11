import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mali_app/application/models/home_monthly_summary_display.dart';
import 'package:mali_app/application/providers/home_providers.dart';
import 'package:mali_app/application/providers/use_case_providers.dart';
import 'package:mali_app/application/providers/wallet_card_providers.dart';
import 'package:mali_app/application/providers/wallet_providers.dart';
import 'package:mali_app/domain/entities/wallet.dart';
import 'package:mali_app/domain/usecases/calculate_net_worth_usecase.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/theme/app_decorations.dart';
import 'package:mali_app/presentation/theme/app_typography.dart';
import 'package:mali_app/presentation/utils/money_display.dart';
import 'package:mali_app/presentation/widgets/wallet/add_wallet_sheet.dart';

class WalletsScreen extends ConsumerStatefulWidget {
  const WalletsScreen({super.key});

  @override
  ConsumerState<WalletsScreen> createState() => _WalletsScreenState();
}

class _WalletsScreenState extends ConsumerState<WalletsScreen> {
  final _pageController = PageController(viewportFraction: 0.9);
  int _selectedIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _openAddWallet() async {
    final created = await AddWalletSheet.show(context);
    if (created == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wallet added.')),
      );
    }
  }

  Future<bool> _archiveWallet(Wallet wallet) async {
    final result = await ref.read(archiveWalletUseCaseProvider)(
      walletId: wallet.id,
    );

    if (!mounted) return false;

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
  Widget build(BuildContext context) {
    final walletsAsync = ref.watch(activeWalletsProvider);
    final summaryAsync = ref.watch(homeMonthlySummaryDisplayProvider);
    final netWorthAsync = ref.watch(homeNetWorthProvider);
    final canPop = GoRouter.of(context).canPop();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: walletsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Could not load wallets: $error'),
            ),
          ),
          data: (wallets) {
            if (_selectedIndex >= wallets.length && wallets.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                setState(() => _selectedIndex = 0);
              });
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Row(
                    children: [
                      if (canPop) ...[
                        _HeaderIconButton(
                          icon: Icons.arrow_back_ios_new_rounded,
                          onPressed: () => context.pop(),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Text(
                          'Wallets',
                          style: AppTypography.money(
                            fontSize: 28,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: _openAddWallet,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.navy,
                          foregroundColor: AppColors.silver,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text(
                          'Add',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: wallets.isEmpty
                      ? _EmptyWallets(onAdd: _openAddWallet)
                      : ListView(
                          padding: const EdgeInsets.only(bottom: 16),
                          children: [
                            SizedBox(
                              height: 210,
                              child: PageView.builder(
                                controller: _pageController,
                                itemCount: wallets.length,
                                onPageChanged: (index) {
                                  setState(() => _selectedIndex = index);
                                },
                                itemBuilder: (context, index) {
                                  final wallet = wallets[index];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 8,
                                    ),
                                    child: _HeroWalletCard(
                                      wallet: wallet,
                                      variant: _HeroWalletVariant.forIndex(index),
                                      onTap: () =>
                                          context.push('/wallets/${wallet.id}'),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                            _PageDots(
                              count: wallets.length,
                              selectedIndex: _selectedIndex,
                            ),
                            const SizedBox(height: 16),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: _MonthFlowCard(summaryAsync: summaryAsync),
                            ),
                            const SizedBox(height: 16),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: DecoratedBox(
                                decoration: AppDecorations.surfaceCard(
                                  radius: 22,
                                  color: AppColors.surfaceContainerLowest,
                                ),
                                child: Column(
                                  children: [
                                    for (var i = 0; i < wallets.length; i++) ...[
                                      if (i > 0)
                                        const Divider(
                                          height: 1,
                                          indent: 90,
                                          endIndent: 16,
                                        ),
                                      Dismissible(
                                        key: ValueKey(wallets[i].id),
                                        direction: DismissDirection.endToStart,
                                        background: Container(
                                          alignment: Alignment.centerRight,
                                          padding:
                                              const EdgeInsets.only(right: 24),
                                          color: AppColors.errorContainer,
                                          child: const Icon(
                                            Icons.archive_outlined,
                                          ),
                                        ),
                                        confirmDismiss: (_) =>
                                            _archiveWallet(wallets[i]),
                                        child: _WalletListTile(
                                          wallet: wallets[i],
                                          emphasize: i == 0,
                                          onTap: () => context.push(
                                            '/wallets/${wallets[i].id}',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
                if (wallets.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: _TotalBar(netWorthAsync: netWorthAsync),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

enum _HeroWalletVariant {
  silver,
  navy,
  light;

  static _HeroWalletVariant forIndex(int index) {
    switch (index % 3) {
      case 0:
        return _HeroWalletVariant.silver;
      case 1:
        return _HeroWalletVariant.navy;
      default:
        return _HeroWalletVariant.light;
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
        side: const BorderSide(color: AppColors.outlineVariant),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(icon, color: AppColors.onSurface, size: 20),
        ),
      ),
    );
  }
}

class _HeroWalletCard extends ConsumerWidget {
  const _HeroWalletCard({
    required this.wallet,
    required this.variant,
    required this.onTap,
  });

  final Wallet wallet;
  final _HeroWalletVariant variant;
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
    final txCount = txAsync.asData?.value.length;

    final background = switch (variant) {
      _HeroWalletVariant.silver => AppColors.silver,
      _HeroWalletVariant.navy => AppColors.navy,
      _HeroWalletVariant.light => AppColors.surfaceContainerLowest,
    };
    final foreground = switch (variant) {
      _HeroWalletVariant.navy => AppColors.onPrimary,
      _ => AppColors.navy,
    };
    final muted = foreground.withValues(alpha: 0.85);

    return Material(
      color: background,
      elevation: variant == _HeroWalletVariant.silver ? 8 : 2,
      shadowColor: AppColors.navy.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(26),
        side: variant == _HeroWalletVariant.navy
            ? BorderSide.none
            : const BorderSide(color: AppColors.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    wallet.currencyCode,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    wallet.name,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                MoneyDisplay.compact(
                  amount: wallet.balance,
                  currencyCode: wallet.currencyCode,
                  trimTrailingZeros: wallet.currencyCode == 'ZWG',
                ),
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      equivalentAsync.asData?.value ??
                          _walletSubtitle(wallet.name),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: muted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (txCount != null)
                    Text(
                      '$txCount transaction${txCount == 1 ? '' : 's'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: muted,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({
    required this.count,
    required this.selectedIndex,
  });

  final int count;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: i == selectedIndex ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == selectedIndex
                  ? AppColors.navy
                  : AppColors.silverDim,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ],
    );
  }
}

class _MonthFlowCard extends StatelessWidget {
  const _MonthFlowCard({required this.summaryAsync});

  final AsyncValue<HomeMonthlySummaryDisplay> summaryAsync;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: AppDecorations.surfaceCard(
        radius: 22,
        color: AppColors.surfaceContainerLowest,
      ),
      child: summaryAsync.when(
        loading: () => const SizedBox(
          height: 48,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        error: (_, _) => Text(
          'Could not load month summary',
          style: theme.textTheme.bodySmall,
        ),
        data: (summary) {
          return Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'In this month',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      MoneyDisplay.compactSigned(
                        amount: summary.income.toString(),
                        currencyCode: summary.displayCurrency.value,
                        prefix: '+',
                      ),
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Out this month',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      MoneyDisplay.compactSigned(
                        amount: summary.expenses.toString(),
                        currencyCode: summary.displayCurrency.value,
                        prefix: '-',
                      ),
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WalletListTile extends ConsumerWidget {
  const _WalletListTile({
    required this.wallet,
    required this.onTap,
    this.emphasize = false,
  });

  final Wallet wallet;
  final VoidCallback onTap;
  final bool emphasize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final equivalentAsync = ref.watch(
      walletEquivalentLabelProvider((
        balance: wallet.balance,
        currencyCode: wallet.currencyCode,
      )),
    );

    final badgeBackground =
        emphasize ? AppColors.navy : AppColors.surfaceContainer;
    final badgeForeground =
        emphasize ? AppColors.silver : const Color(0xFF3A4560);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: badgeBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                wallet.currencyCode,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: badgeForeground,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    wallet.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    equivalentAsync.asData?.value ??
                        _walletSubtitle(wallet.name),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              MoneyDisplay.compact(
                amount: wallet.balance,
                currencyCode: wallet.currencyCode,
                trimTrailingZeros: wallet.currencyCode == 'ZWG',
              ),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalBar extends StatelessWidget {
  const _TotalBar({required this.netWorthAsync});

  final AsyncValue<CalculateNetWorthResult> netWorthAsync;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Text(
            'Total in USD',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.onNavyMuted,
            ),
          ),
          const Spacer(),
          netWorthAsync.when(
            loading: () => const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.silver,
              ),
            ),
            error: (_, _) => Text(
              '—',
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppColors.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            data: (netWorth) => Text(
              MoneyDisplay.compact(
                amount: netWorth.total.amount.toString(),
                currencyCode: netWorth.total.currency.value,
              ),
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppColors.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyWallets extends StatelessWidget {
  const _EmptyWallets({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'No wallets yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add your first wallet'),
            ),
          ],
        ),
      ),
    );
  }
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
