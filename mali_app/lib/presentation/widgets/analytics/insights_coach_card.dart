import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mali_app/application/providers/budget_providers.dart';
import 'package:mali_app/application/providers/category_providers.dart';
import 'package:mali_app/application/providers/display_currency_provider.dart';
import 'package:mali_app/presentation/constants/system_categories.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/theme/app_decorations.dart';
import 'package:mali_app/presentation/utils/insights_coach_tip.dart';

/// Navy coach card with a budget tip and optional “Move $X” CTA.
class InsightsCoachCard extends ConsumerWidget {
  const InsightsCoachCard({
    this.now,
    this.onAction,
    super.key,
  });

  static const Key cardKey = Key('insights-coach-card');
  static const Key actionKey = Key('insights-coach-action');

  final DateTime? now;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(currentMonthBudgetsProvider);
    final currencyCode = ref.watch(displayCurrencyProvider).value;
    final effectiveNow = now ?? DateTime.now();

    return budgetsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (budgets) {
        final tip = InsightsCoachTip.fromBudgets(
          budgets: budgets,
          now: effectiveNow,
          categoryName: (id) {
            final category = ref.read(categoryByIdProvider(id));
            return category?.name ??
                SystemCategories.nameFor(id, fallback: 'This budget');
          },
        );
        if (tip == null) {
          return const SizedBox.shrink();
        }

        final cta = tip.ctaLabel(currencyCode: currencyCode);
        final message = tip.message(currencyCode: currencyCode);
        final boldPercent = '${tip.stressedPercent}%';

        return Container(
          key: cardKey,
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          decoration: AppDecorations.heroCard(
            radius: AppDecorations.radiusXl,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: AppDecorations.iconTile(
                  AppColors.silver,
                  radius: 12,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.lightbulb_outline,
                  size: 20,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        style: const TextStyle(
                          color: AppColors.onPrimary,
                          fontSize: 14.5,
                          height: 1.45,
                          fontWeight: FontWeight.w400,
                        ),
                        children: _messageSpans(
                          message: message,
                          boldToken: boldPercent,
                        ),
                      ),
                    ),
                    if (cta != null) ...[
                      const SizedBox(height: 12),
                      FilledButton(
                        key: actionKey,
                        onPressed: onAction ??
                            () => context.push('/budgets'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.silver,
                          foregroundColor: AppColors.navy,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: Text(cta),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static List<InlineSpan> _messageSpans({
    required String message,
    required String boldToken,
  }) {
    final index = message.indexOf(boldToken);
    if (index < 0) {
      return [TextSpan(text: message)];
    }
    return [
      TextSpan(text: message.substring(0, index)),
      TextSpan(
        text: boldToken,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      TextSpan(text: message.substring(index + boldToken.length)),
    ];
  }
}
