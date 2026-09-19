import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mali_app/application/providers/exchange_rate_settings_providers.dart';
import 'package:mali_app/application/providers/home_providers.dart';
import 'package:mali_app/application/providers/use_case_providers.dart';
import 'package:mali_app/application/providers/wallet_providers.dart';
import 'package:mali_app/domain/entities/wallet.dart';
import 'package:mali_app/presentation/screens/settings/export_screen.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/theme/app_decorations.dart';
import 'package:mali_app/presentation/theme/app_typography.dart';
import 'package:mali_app/presentation/utils/exchange_rate_labels.dart';
import 'package:mali_app/presentation/utils/money_display.dart';
import 'package:mali_app/presentation/widgets/settings/edit_exchange_rate_sheet.dart';
import 'package:mali_app/presentation/widgets/sovereign/sovereign_app_bar.dart';
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
    WidgetRef ref,
    BuildContext context,
    Wallet wallet,
  ) async {
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

  Map<String, List<Wallet>> _groupByCurrency(List<Wallet> wallets) {
    final groups = <String, List<Wallet>>{};
    for (final wallet in wallets) {
      groups.putIfAbsent(wallet.currencyCode, () => []).add(wallet);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletsAsync = ref.watch(activeWalletsProvider);
    final ratesAsync = ref.watch(exchangeRateSettingsItemsProvider);
    final lastUpdatedAsync = ref.watch(exchangeRatesLastUpdatedProvider);

    return Scaffold(
      appBar: const SovereignAppBar(title: 'Manage Wallets & Rates'),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddWallet(context),
        tooltip: 'Add wallet',
        backgroundColor: AppColors.primaryContainer,
        foregroundColor: AppColors.onPrimaryContainer,
        child: const Icon(Icons.add),
      ),
      body: walletsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Could not load wallets: $error'),
          ),
        ),
        data: (wallets) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            children: [
              _MarketRatesSection(
                ratesAsync: ratesAsync,
                lastUpdatedAsync: lastUpdatedAsync,
              ),
              const SizedBox(height: 40),
              Text(
                'ASSET DISTRIBUTION',
                style: AppTypography.sectionLabel(context),
              ),
              const SizedBox(height: 4),
              Text(
                'Your Wallets',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 24),
              if (wallets.isEmpty)
                _EmptyWallets(onAdd: () => _openAddWallet(context))
              else
                ..._groupByCurrency(wallets).entries.map(
                  (entry) => _WalletGroup(
                    currencyCode: entry.key,
                    wallets: entry.value,
                    onArchive: (wallet) => _archiveWallet(ref, context, wallet),
                  ),
                ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => context.push(ExportScreen.location),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  backgroundColor: AppColors.surfaceContainerHighest,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppDecorations.radiusXl,
                    ),
                  ),
                ),
                icon: const Icon(Icons.receipt_long),
                label: const Text('Currency Transfer Log'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MarketRatesSection extends ConsumerWidget {
  const _MarketRatesSection({
    required this.ratesAsync,
    required this.lastUpdatedAsync,
  });

  final AsyncValue<List<ExchangeRateSettingsItem>> ratesAsync;
  final AsyncValue<DateTime?> lastUpdatedAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'REAL-TIME DATA',
                  style: AppTypography.sectionLabel(context),
                ),
                Text(
                  'Market Rates',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            lastUpdatedAsync.when(
              data: (updatedAt) => Text(
                updatedAt == null
                    ? 'No rates yet'
                    : ExchangeRateLabels.lastUpdated(
                        updatedAt,
                        DateTime.now(),
                      ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
        const SizedBox(height: 24),
        ratesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Text('Could not load rates: $error'),
          data: (items) => Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(height: 16),
                _RateCard(item: items[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _RateCard extends ConsumerWidget {
  const _RateCard({required this.item});

  final ExchangeRateSettingsItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final pairLabel =
        '${item.pair.base.value} / ${item.pair.quote.value}';
    final rateValue = item.rate?.rate ?? '';
    final isPrimary = item.pair.base.value == 'USD';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppDecorations.ghostBorderCard(radius: AppDecorations.radiusMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isPrimary
                          ? AppColors.primaryContainer
                          : AppColors.secondaryContainer)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isPrimary ? Icons.currency_exchange : Icons.show_chart,
                  color: isPrimary ? AppColors.primary : AppColors.secondary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                pairLabel,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
            ),
            child: Text(
              rateValue.isEmpty
                  ? '1.00 ${item.pair.base.value} = —'
                  : '1.00 ${item.pair.base.value} = $rateValue ${item.pair.quote.value}',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () async {
              final saved = await EditExchangeRateSheet.show(
                context,
                pair: item.pair,
                initialRate: item.rate?.rate,
              );
              if (saved == true && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Exchange rate saved.')),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor:
                  isPrimary ? AppColors.primary : AppColors.secondary,
            ),
            child: const Text('SET RATE'),
          ),
        ],
      ),
    );
  }
}

class _WalletGroup extends StatelessWidget {
  const _WalletGroup({
    required this.currencyCode,
    required this.wallets,
    required this.onArchive,
  });

  final String currencyCode;
  final List<Wallet> wallets;
  final Future<bool> Function(Wallet wallet) onArchive;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  color: AppColors.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '$currencyCode WALLETS',
                  style: AppTypography.sectionLabel(context).copyWith(
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 1,
                  color: AppColors.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: AppDecorations.surfaceCard(radius: AppDecorations.radiusXl),
            child: Column(
              children: [
                for (var i = 0; i < wallets.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: AppColors.surfaceContainer,
                    ),
                  Dismissible(
                    key: ValueKey(wallets[i].id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 24),
                      color: AppColors.errorContainer,
                      child: const Icon(Icons.archive_outlined),
                    ),
                    confirmDismiss: (_) => onArchive(wallets[i]),
                    child: _WalletRow(
                      wallet: wallets[i],
                      onTap: () =>
                          context.push('/wallets/${wallets[i].id}'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletRow extends StatelessWidget {
  const _WalletRow({required this.wallet, required this.onTap});

  final Wallet wallet;
  final VoidCallback onTap;

  IconData _iconForWallet() {
    final lower = wallet.name.toLowerCase();
    if (lower.contains('ecocash') || lower.contains('onemoney')) {
      return Icons.smartphone;
    }
    if (lower.contains('bank')) {
      return Icons.account_balance;
    }
    return Icons.payments;
  }

  Color _iconColor() {
    switch (wallet.currencyCode) {
      case 'ZWG':
        return AppColors.primary;
      case 'ZAR':
        return AppColors.tertiary;
      default:
        return AppColors.onPrimary;
    }
  }

  String _walletSubtitle(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('ecocash') || lower.contains('onemoney')) {
      return 'Mobile Money';
    }
    if (lower.contains('bank')) {
      return 'Bank Account';
    }
    if (lower.contains('cash')) {
      return 'Physical Currency';
    }
    return 'Digital Wallet';
  }

  Color _iconBackground() {
    switch (wallet.currencyCode) {
      case 'ZWG':
        return AppColors.primary.withValues(alpha: 0.1);
      case 'ZAR':
        return AppColors.tertiaryContainer.withValues(alpha: 0.1);
      default:
        return AppColors.primaryContainer;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _iconBackground(),
                borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
              ),
              child: Icon(_iconForWallet(), color: _iconColor()),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    wallet.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    _walletSubtitle(wallet.name),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  MoneyDisplay.withCurrency(
                    amount: wallet.balance,
                    currencyCode: wallet.currencyCode,
                  ),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: AppColors.onSurfaceVariant,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyWallets extends StatelessWidget {
  const _EmptyWallets({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          const Text('No wallets yet'),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add your first wallet'),
          ),
        ],
      ),
    );
  }
}
