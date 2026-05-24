import 'package:flutter/material.dart';

class PinKeypad extends StatelessWidget {
  const PinKeypad({
    required this.onDigit,
    required this.onBackspace,
    super.key,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    const keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', 'back'],
    ];

    return Column(
      children: keys.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: row.map((key) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: _KeyButton(
                    label: key,
                    onDigit: onDigit,
                    onBackspace: onBackspace,
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}

class _KeyButton extends StatelessWidget {
  const _KeyButton({
    required this.label,
    required this.onDigit,
    required this.onBackspace,
  });

  final String label;
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) {
      return const SizedBox(height: 56);
    }

    final theme = Theme.of(context);

    if (label == 'back') {
      return SizedBox(
        height: 56,
        child: IconButton(
          key: const Key('pin-keypad-backspace'),
          onPressed: onBackspace,
          icon: const Icon(Icons.backspace_outlined),
        ),
      );
    }

    return SizedBox(
      height: 56,
      child: FilledButton.tonal(
        key: Key('pin-key-$label'),
        onPressed: () => onDigit(label),
        style: FilledButton.styleFrom(
          shape: const CircleBorder(),
          textStyle: theme.textTheme.headlineSmall,
        ),
        child: Text(label),
      ),
    );
  }
}
