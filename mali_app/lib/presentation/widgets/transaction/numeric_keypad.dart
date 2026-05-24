import 'package:flutter/material.dart';
import 'package:mali_app/domain/value_objects/currency_code.dart';
import 'package:mali_app/presentation/utils/amount_keypad_input.dart';

/// Custom numeric keypad for currency amount entry.
class NumericKeypad extends StatelessWidget {
  const NumericKeypad({
    required this.amount,
    required this.currency,
    required this.onChanged,
    super.key,
  });

  final String amount;
  final CurrencyCode currency;
  final ValueChanged<String> onChanged;

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
    final theme = Theme.of(context);
    final displayAmount = AmountKeypadInput.formatDisplay(
      amount,
      currency.decimalPlaces,
    );
    final allowsDecimal = currency.decimalPlaces > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          displayAmount,
          key: const Key('numeric-keypad-amount'),
          textAlign: TextAlign.center,
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          currency.value,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.6,
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
              child: Icon(
                Icons.backspace_outlined,
                color: theme.colorScheme.onSurface,
              ),
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
    this.child,
    this.enabled = true,
    super.key,
  });

  final VoidCallback onTap;
  final String? label;
  final Widget? child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: enabled
          ? theme.colorScheme.surfaceContainerHighest
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Center(
          child: child ??
              Text(
                label!,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: enabled
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
        ),
      ),
    );
  }
}
