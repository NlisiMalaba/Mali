import 'package:flutter/material.dart';
import 'package:mali_app/core/constants/pin_lock_constants.dart';

class PinDots extends StatelessWidget {
  const PinDots({
    required this.enteredLength,
    super.key,
  });

  final int enteredLength;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(PinLockConstants.pinLength, (index) {
        final filled = index < enteredLength;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
            ),
          ),
        );
      }),
    );
  }
}
