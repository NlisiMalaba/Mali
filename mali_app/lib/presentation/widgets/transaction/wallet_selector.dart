import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mali_app/application/providers/recent_wallets_provider.dart';
import 'package:mali_app/domain/entities/wallet.dart';
import 'package:mali_app/presentation/utils/wallet_ordering.dart';
import 'package:mali_app/presentation/widgets/transaction/transfer_exchange_rate_field.dart';
import 'package:mali_app/presentation/widgets/transaction/wallet_selector_chip.dart';

enum WalletSelectorMode { single, transfer }

class WalletSelector extends ConsumerWidget {
  const WalletSelector({
    required this.wallets,
    required this.mode,
    required this.fromWalletId,
    required this.toWalletId,
    required this.onFromWalletChanged,
    required this.onToWalletChanged,
    required this.exchangeRateController,
    required this.onExchangeRateChanged,
    this.suggestedExchangeRate,
    super.key,
  });

  final List<Wallet> wallets;
  final WalletSelectorMode mode;
  final String? fromWalletId;
  final String? toWalletId;
  final ValueChanged<Wallet> onFromWalletChanged;
  final ValueChanged<Wallet> onToWalletChanged;
  final TextEditingController exchangeRateController;
  final ValueChanged<String> onExchangeRateChanged;
  final String? suggestedExchangeRate;

  Future<void> _selectFromWallet(WidgetRef ref, Wallet wallet) async {
    await ref.read(recentWalletsProvider.notifier).recordUsage(wallet.id);
    onFromWalletChanged(wallet);
  }

  Wallet? _walletById(String? walletId) {
    if (walletId == null) {
      return null;
    }
    for (final wallet in wallets) {
      if (wallet.id == walletId) {
        return wallet;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final recentIds = ref.watch(recentWalletIdsProvider);
    final ordered = WalletOrdering.withRecentFirst(
      wallets: wallets,
      recentWalletIds: recentIds,
    );
    final fromWallet = _walletById(fromWalletId);
    final toWallet = _walletById(toWalletId);

    if (wallets.isEmpty) {
      return Text(
        'Create a wallet before logging transactions.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.error,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          mode == WalletSelectorMode.transfer ? 'From wallet' : 'Wallet',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        _WalletStrip(
          wallets: ordered,
          selectedWalletId: fromWalletId,
          keyPrefix: 'from',
          onWalletSelected: (wallet) => _selectFromWallet(ref, wallet),
        ),
        if (mode == WalletSelectorMode.transfer) ...[
          const SizedBox(height: 16),
          Text(
            'To wallet',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          _WalletStrip(
            wallets: ordered,
            selectedWalletId: toWalletId,
            excludedWalletId: fromWalletId,
            keyPrefix: 'to',
            onWalletSelected: onToWalletChanged,
          ),
          if (fromWallet != null && toWallet != null) ...[
            const SizedBox(height: 16),
            TransferExchangeRateField(
              fromCurrency: fromWallet.currencyCode,
              toCurrency: toWallet.currencyCode,
              controller: exchangeRateController,
              suggestedRate: suggestedExchangeRate,
              onChanged: onExchangeRateChanged,
            ),
          ],
        ],
      ],
    );
  }
}

class _WalletStrip extends StatelessWidget {
  const _WalletStrip({
    required this.wallets,
    required this.selectedWalletId,
    required this.onWalletSelected,
    required this.keyPrefix,
    this.excludedWalletId,
  });

  final List<Wallet> wallets;
  final String? selectedWalletId;
  final String? excludedWalletId;
  final ValueChanged<Wallet> onWalletSelected;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    final visibleWallets = excludedWalletId == null
        ? wallets
        : wallets.where((wallet) => wallet.id != excludedWalletId).toList();

    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: visibleWallets.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final wallet = visibleWallets[index];
          return WalletSelectorChip(
            key: Key('wallet-selector-$keyPrefix-${wallet.id}'),
            wallet: wallet,
            isSelected: selectedWalletId == wallet.id,
            onTap: () => onWalletSelected(wallet),
          );
        },
      ),
    );
  }
}
