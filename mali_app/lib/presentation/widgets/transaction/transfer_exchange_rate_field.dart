import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

class TransferExchangeRateField extends StatelessWidget {
  const TransferExchangeRateField({
    required this.fromCurrency,
    required this.toCurrency,
    required this.controller,
    required this.suggestedRate,
    required this.onChanged,
    super.key,
  });

  final String fromCurrency;
  final String toCurrency;
  final TextEditingController controller;
  final String? suggestedRate;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    if (fromCurrency == toCurrency) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Exchange rate',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('transfer-exchange-rate'),
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: '1 $fromCurrency =',
            suffixText: toCurrency,
            helperText: suggestedRate == null
                ? 'Enter the rate used for this transfer.'
                : 'Suggested rate: $suggestedRate',
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

bool isValidExchangeRate(String? value) {
  if (value == null || value.trim().isEmpty) {
    return false;
  }
  try {
    return Decimal.parse(value.trim()) > Decimal.zero;
  } catch (_) {
    return false;
  }
}
