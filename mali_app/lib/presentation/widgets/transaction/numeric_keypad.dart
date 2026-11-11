import 'package:flutter/material.dart';
import 'package:mali_app/domain/value_objects/currency_code.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/theme/app_typography.dart';
import 'package:mali_app/presentation/utils/amount_keypad_input.dart';

/// Custom numeric keypad for currency amount entry.
class NumericKeypad extends StatelessWidget {
  const NumericKeypad({
    required this.amount,
    required this.currency,
    required this.onChanged,
    this.showAmountDisplay = true,
    super.key,
  });

  final String amount;
  final CurrencyCode currency;
  final ValueChanged<String> onChanged;
  final bool showAmountDisplay;

  static const _digitKeys = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
  ];

  void _appendKey(String key) {
    onChanged(
      AmountKeypadInput.applyKey(
        current: amount,
        key: key,
        decimalPlaces: currency.decimalPlaces,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayAmount = AmountKeypadInput.formatDisplay(
      amount,
      currency.decimalPlaces,
    );
    final allowsDecimal = currency.decimalPlaces > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showAmountDisplay) ...[
          Text(
            displayAmount,
            key: const Key('numeric-keypad-amount'),
            textAlign: TextAlign.center,
            style: AppTypography.money(
              fontSize: 40,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            currency.value,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
        ],
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.55,
          children: [
            for (final key in _digitKeys)
              _KeypadButton(
                key: Key('numeric-keypad-$key'),
                label: key,
                onTap: () => _appendKey(key),
              ),
            _KeypadButton(
              key: const Key('numeric-keypad-decimal'),
              label: '.',
              enabled: allowsDecimal,
              onTap: () => _appendKey('.'),
            ),
            _KeypadButton(
              key: const Key('numeric-keypad-0'),
              label: '0',
              onTap: () => _appendKey('0'),
            ),
            _KeypadButton(
              key: const Key('numeric-keypad-backspace'),
              onTap: () => _appendKey('backspace'),
              label: '⌫',
            ),
          ],
        ),
      ],
    );
  }
}

class _KeypadButton extends StatelessWidget {
  const _KeypadButton({
    required this.onTap,
    this.label,
    this.enabled = true,
    super.key,
  });

  final VoidCallback onTap;
  final String? label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled
          ? AppColors.surfaceContainerLowest
          : AppColors.surfaceContainerLowest.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Center(
          child: Text(
            label!,
            style: AppTypography.money(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: enabled
                  ? AppColors.onSurface
                  : AppColors.onSurface.withValues(alpha: 0.35),
            ),
          ),
        ),
      ),
    );
  }
}
