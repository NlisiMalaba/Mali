import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mali_app/application/providers/transaction_list_filters_provider.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';

class ActivityTypeFilterChips extends ConsumerWidget {
  const ActivityTypeFilterChips({
    required this.scopedWalletId,
    super.key,
  });

  final String? scopedWalletId;

  static const _options = <(String label, String? type)>[
    ('All', null),
    ('Expense', 'expense'),
    ('Income', 'income'),
    ('Transfer', 'transfer'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(transactionListFiltersProvider(scopedWalletId));
    final theme = Theme.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Row(
        children: [
          for (var index = 0; index < _options.length; index++) ...[
            if (index > 0) const SizedBox(width: 8),
            _TypeChip(
              label: _options[index].$1,
              selected: filters.type == _options[index].$2,
              onTap: () => ref
                  .read(transactionListFiltersProvider(scopedWalletId).notifier)
                  .setType(_options[index].$2),
              textStyle: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.textStyle,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.navy : AppColors.surfaceContainerLowest,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? AppColors.navy : AppColors.outlineVariant,
        ),
      ),
      child: InkWell(
        key: Key('activity-type-chip-$label'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            label,
            style: textStyle?.copyWith(
              color: selected ? AppColors.silver : AppColors.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
