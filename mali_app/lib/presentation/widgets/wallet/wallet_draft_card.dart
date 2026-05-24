import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mali_app/domain/value_objects/currency_code.dart';
import 'package:mali_app/presentation/utils/currency_display.dart';
import 'package:mali_app/presentation/wallet/wallet_form_validators.dart';

class WalletDraftCard extends StatelessWidget {
  const WalletDraftCard({
    required this.currency,
    required this.nameController,
    required this.balanceController,
    required this.nameTouched,
    required this.balanceTouched,
    required this.onNameBlur,
    required this.onBalanceBlur,
    super.key,
  });

  final CurrencyCode currency;
  final TextEditingController nameController;
  final TextEditingController balanceController;
  final bool nameTouched;
  final bool balanceTouched;
  final VoidCallback onNameBlur;
  final VoidCallback onBalanceBlur;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  CurrencyDisplay.flagEmoji(currency),
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    currency.value,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: nameController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Wallet name',
                hintText: 'e.g. EcoCash ${currency.value}',
              ),
              onTapOutside: (_) => onNameBlur(),
              onEditingComplete: onNameBlur,
              validator: (value) => WalletFormValidators.walletName(
                value,
                touched: nameTouched,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: balanceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Opening balance',
                suffixText: currency.value,
              ),
              onTapOutside: (_) => onBalanceBlur(),
              onEditingComplete: onBalanceBlur,
              validator: (value) => WalletFormValidators.openingBalance(
                value,
                touched: balanceTouched,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
