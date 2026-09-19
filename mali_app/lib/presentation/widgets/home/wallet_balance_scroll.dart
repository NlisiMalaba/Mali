import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mali_app/application/providers/wallet_providers.dart';
import 'package:mali_app/domain/entities/wallet.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/theme/app_decorations.dart';
import 'package:mali_app/presentation/theme/app_typography.dart';
import 'package:mali_app/presentation/utils/money_display.dart';
import 'package:mali_app/presentation/widgets/common/fade_slide_in.dart';
import 'package:mali_app/presentation/widgets/common/pressable_scale.dart';
import 'package:mali_app/presentation/widgets/common/shimmer_box.dart';

class WalletBalanceScroll extends ConsumerWidget {
  const WalletBalanceScroll({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletsAsync = ref.watch(activeWalletsProvider);

    return walletsAsync.when(
      loading: () => SizedBox(
        height: 140,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: 3,
          separatorBuilder: (_, __) => const SizedBox(width: 16),
          itemBuilder: (_, __) => const ShimmerBox(width: 176, height: 140),
        ),
      ),
      error: (error, _) => Text('Could not load wallets: $error'),
      data: (wallets) {
        if (wallets.isEmpty) {
          return const SizedBox.shrink();
        }

        return SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: wallets.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final wallet = wallets[index];
              return FadeSlideIn(
                index: index,
                child: _CompactWalletCard(
                  wallet: wallet,
                  onTap: () => context.push('/wallets/${wallet.id}'),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _CompactWalletCard extends ConsumerWidget {
  const _CompactWalletCard({
    required this.wallet,
    this.onTap,
  });

  final Wallet wallet;
  final VoidCallback? onTap;

  IconData _walletIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('ecocash') || lower.contains('onemoney')) {
      return Icons.account_balance_wallet;
    }
    if (lower.contains('inn')) {
      return Icons.shopping_basket_outlined;
    }
    if (wallet.currencyCode == 'ZAR') {
      return Icons.currency_exchange;
    }
    return Icons.payments_outlined;
  }

  Color _accentColor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('ecocash') || lower.contains('onemoney')) {
      return AppColors.secondary;
    }
    if (lower.contains('inn')) {
      return AppColors.tertiary;
    }
    if (wallet.currencyCode == 'ZAR') {
      return AppColors.secondaryContainer;
    }
    return AppColors.primaryContainer;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isMobileMoney = wallet.name.toLowerCase().contains('ecocash') ||
        wallet.name.toLowerCase().contains('onemoney');

    return PressableScale(
      onTap: onTap,
      child: Container(
        width: 176,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isMobileMoney
              ? AppColors.surfaceContainerHighest
              : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppDecorations.radiusXl),
          border: isMobileMoney
              ? const Border(
                  left: BorderSide(color: AppColors.secondary, width: 4),
                )
              : null,
          boxShadow: AppDecorations.softCardShadow(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              _walletIcon(wallet.name),
              color: _accentColor(wallet.name),
              size: 28,
            ),
            const Spacer(),
            Text(
              wallet.name.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.sectionLabel(context).copyWith(
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              MoneyDisplay.withCurrency(
                amount: wallet.balance,
                currencyCode: wallet.currencyCode,
              ),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
