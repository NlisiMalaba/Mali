import 'package:flutter/material.dart';
import 'package:mali_app/core/constants/pin_lock_constants.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/theme/app_motion.dart';

enum PinChrome { light, dark }

class PinDots extends StatelessWidget {
  const PinDots({
    required this.enteredLength,
    this.chrome = PinChrome.light,
    this.hasError = false,
    super.key,
  });

  final int enteredLength;
  final PinChrome chrome;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = chrome == PinChrome.dark;
    final emptyColor = isDark
        ? Colors.transparent
        : theme.colorScheme.outlineVariant;
    final emptyBorder = isDark
        ? AppColors.pinDotRing
        : theme.colorScheme.outlineVariant;
    final filledColor = isDark
        ? AppColors.silver
        : theme.colorScheme.primary;
    final errorColor = theme.colorScheme.error;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(PinLockConstants.pinLength, (index) {
        final filled = index < enteredLength;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: isDark ? 9 : 8),
          child: AnimatedContainer(
            duration: AppMotion.resolve(context, AppMotion.fast),
            width: isDark ? 16 : 14,
            height: isDark ? 16 : 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: hasError
                  ? errorColor
                  : filled
                      ? filledColor
                      : emptyColor,
              border: Border.all(
                color: hasError
                    ? errorColor
                    : filled
                        ? filledColor
                        : emptyBorder,
                width: isDark ? 1.6 : (filled ? 0 : 1),
              ),
            ),
          ),
        );
      }),
    );
  }
}
