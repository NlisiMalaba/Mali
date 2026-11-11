import 'package:flutter/material.dart';
import 'package:mali_app/domain/value_objects/currency_code.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/utils/currency_display.dart';

/// Compact currency tile for create/edit sheets (goal, wallet, budget, etc.).
class CurrencyOptionCard extends StatelessWidget {
  const CurrencyOptionCard({
    required this.currency,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final CurrencyCode currency;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = isSelected ? AppColors.navy : AppColors.onSurface;
    final muted = isSelected
        ? AppColors.navy.withValues(alpha: 0.7)
        : AppColors.onSurfaceVariant;

    return Material(
      key: Key('currency-${currency.value}'),
      color: isSelected ? AppColors.silver : AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.navy : AppColors.outlineVariant,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                CurrencyDisplay.flagEmoji(currency),
                style: const TextStyle(fontSize: 20, height: 1),
              ),
              const SizedBox(height: 4),
              Text(
                currency.value,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: foreground,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                CurrencyDisplay.label(currency),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: muted,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
