import 'package:flutter/material.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/theme/app_typography.dart';

/// Notification-style sheet prompting the user to create their first wallet.
class NoWalletAlertSheet extends StatelessWidget {
  const NoWalletAlertSheet({
    required this.onCreateWallet,
    super.key,
  });

  static const Key sheetKey = Key('no-wallet-alert-sheet');

  final VoidCallback onCreateWallet;

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onCreateWallet,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return NoWalletAlertSheet(
          onCreateWallet: () {
            Navigator.of(sheetContext).pop();
            onCreateWallet();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        key: sheetKey,
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.warningContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.notifications_active_outlined,
                    color: AppColors.warningText,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'No wallet yet',
                    style: AppTypography.money(
                      fontSize: 22,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'Create a wallet to track balances, log spending, and unlock '
              'budgets and goals.',
              style: TextStyle(
                fontSize: 15,
                height: 1.4,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: onCreateWallet,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  foregroundColor: AppColors.silver,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Create wallet',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
