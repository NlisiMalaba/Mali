import 'package:flutter/material.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/theme/app_decorations.dart';
import 'package:mali_app/presentation/theme/app_typography.dart';

/// Home callout shown when the signed-in user has no wallets yet.
class CreateWalletPromptCard extends StatelessWidget {
  const CreateWalletPromptCard({
    required this.onCreateWallet,
    super.key,
  });

  static const Key cardKey = Key('create-wallet-prompt-card');

  final VoidCallback onCreateWallet;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: cardKey,
      color: AppColors.navy,
      borderRadius: BorderRadius.circular(AppDecorations.radiusXl),
      child: InkWell(
        onTap: onCreateWallet,
        borderRadius: BorderRadius.circular(AppDecorations.radiusXl),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 16, 18),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.navyRaised,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: AppColors.silver,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create your first wallet',
                      style: AppTypography.money(
                        fontSize: 17,
                        color: AppColors.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Add a wallet to start tracking balances and spending.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.3,
                        color: AppColors.onNavyMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right,
                color: AppColors.silver,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
