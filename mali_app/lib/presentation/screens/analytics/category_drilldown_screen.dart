import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mali_app/application/models/category_month_query.dart';
import 'package:mali_app/application/providers/analytics_providers.dart';
import 'package:mali_app/application/providers/category_providers.dart';
import 'package:mali_app/presentation/utils/money_display.dart';
import 'package:mali_app/presentation/widgets/analytics/analytics_breadcrumb_bar.dart';
import 'package:mali_app/presentation/widgets/transaction/transaction_tile.dart';

class CategoryDrilldownScreen extends ConsumerWidget {
  const CategoryDrilldownScreen({
    required this.categoryId,
    required this.year,
    required this.month,
    super.key,
  });

  static const Key screenKey = Key('category-drilldown-screen');
  static const Key totalKey = Key('category-drilldown-total');

  static String location({
    required String categoryId,
    required DateTime month,
  }) {
    return '/analytics/categories/$categoryId'
        '?year=${month.year}&month=${month.month}';
  }

  final String categoryId;
  final int year;
  final int month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final query = CategoryMonthQuery(
      categoryId: categoryId,
      year: year,
      month: month,
    );
    final category = ref.watch(categoryByIdProvider(categoryId));
    final categoryName = category?.name ?? 'Category';
    final transactionsAsync =
        ref.watch(categoryMonthTransactionsProvider(query));
    final totalAsync = ref.watch(categoryMonthDisplayTotalProvider(query));
    final monthLabel = DateFormat.yMMMM().format(DateTime(year, month));

    return Scaffold(
      key: screenKey,
      appBar: AppBar(
        title: Text(categoryName),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnalyticsBreadcrumbBar(categoryName: categoryName),
          Expanded(
            child: transactionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Could not load transactions: $error'),
                ),
              ),
              data: (transactions) {
                return ListView(
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 32),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            monthLabel,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.65),
                            ),
                          ),
                          const SizedBox(height: 8),
                          totalAsync.when(
                            loading: () => const SizedBox(
                              height: 28,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            ),
                            error: (error, _) =>
                                Text('Could not load total: $error'),
                            data: (total) => Text(
                              MoneyDisplay.withCurrency(
                                amount: total.amount.toString(),
                                currencyCode: total.currency.value,
                              ),
                              key: totalKey,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (transactions.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'No transactions in this category.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.65),
                          ),
                        ),
                      )
                    else
                      for (final transaction in transactions)
                        TransactionTile(transaction: transaction),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
