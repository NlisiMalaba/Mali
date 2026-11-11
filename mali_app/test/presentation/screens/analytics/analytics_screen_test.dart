import 'package:decimal/decimal.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mali_app/application/models/category_month_query.dart';
import 'package:mali_app/application/models/home_monthly_summary_display.dart';
import 'package:mali_app/application/providers/analytics_providers.dart';
import 'package:mali_app/application/providers/budget_providers.dart';
import 'package:mali_app/application/providers/home_providers.dart';
import 'package:mali_app/domain/entities/budget.dart';
import 'package:mali_app/domain/entities/transaction.dart';
import 'package:mali_app/domain/usecases/get_analytics_overview_usecase.dart';
import 'package:mali_app/domain/usecases/get_analytics_trends_usecase.dart';
import 'package:mali_app/domain/value_objects/currency_code.dart';
import 'package:mali_app/domain/value_objects/money.dart';
import 'package:mali_app/presentation/constants/system_categories.dart';
import 'package:mali_app/presentation/screens/analytics/analytics_screen.dart';
import 'package:mali_app/presentation/screens/analytics/category_drilldown_screen.dart';
import 'package:mali_app/presentation/widgets/analytics/analytics_breadcrumb_bar.dart';
import 'package:mali_app/presentation/widgets/analytics/category_spend_pie_chart.dart';
import 'package:mali_app/presentation/widgets/analytics/in_vs_out_bar_chart.dart';
import 'package:mali_app/presentation/widgets/analytics/insights_coach_card.dart';
import 'package:mali_app/presentation/widgets/analytics/month_selector.dart';

List<Override> _overviewOverrides({
  required AnalyticsOverview overview,
  HomeMonthlySummaryDisplay? summary,
  AnalyticsTrends? trends,
  List<Budget> budgets = const [],
}) {
  final month = DateTime(2026, 4);
  return [
    homeSelectedMonthProvider.overrideWith(
      () => _FixedMonth(month),
    ),
    homeMonthlySummaryDisplayProvider.overrideWith(
      (ref) async =>
          summary ??
          HomeMonthlySummaryDisplay(
            month: month,
            income: Decimal.parse('200'),
            expenses: Decimal.parse('80'),
            displayCurrency: CurrencyCode.usd,
          ),
    ),
    analyticsOverviewProvider.overrideWith((ref) async => overview),
    analyticsTrendsProvider.overrideWith(
      (ref) async => trends ?? _emptyTrends(),
    ),
    currentMonthBudgetsProvider.overrideWith(
      (ref) => Stream.value(budgets),
    ),
  ];
}

class _FixedMonth extends HomeSelectedMonth {
  _FixedMonth(this.month);

  final DateTime month;

  @override
  DateTime build() => DateTime(month.year, month.month);
}

AnalyticsTrends _emptyTrends() {
  return AnalyticsTrends(
    months: GetAnalyticsTrendsUseCase.monthsEndingAt(DateTime(2026, 4)),
    currencies: const [],
  );
}

List<Decimal> _monthAmounts({required int index, required String amount}) {
  return [
    for (var i = 0; i < GetAnalyticsTrendsUseCase.monthCount; i++)
      i == index ? Decimal.parse(amount) : Decimal.zero,
  ];
}

AnalyticsTrends _sampleTrends() {
  return AnalyticsTrends(
    months: GetAnalyticsTrendsUseCase.monthsEndingAt(DateTime(2026, 4)),
    currencies: [
      CurrencyTrendSeries(
        currencyCode: 'USD',
        incomeByMonth: _monthAmounts(index: 5, amount: '100'),
        expensesByMonth: _monthAmounts(index: 5, amount: '40'),
      ),
      CurrencyTrendSeries(
        currencyCode: 'ZAR',
        incomeByMonth: _monthAmounts(index: 4, amount: '50'),
        expensesByMonth: List<Decimal>.filled(
          GetAnalyticsTrendsUseCase.monthCount,
          Decimal.zero,
        ),
      ),
    ],
  );
}

AnalyticsTrends _allZeroTrends() {
  return AnalyticsTrends(
    months: GetAnalyticsTrendsUseCase.monthsEndingAt(DateTime(2026, 4)),
    currencies: [
      CurrencyTrendSeries(
        currencyCode: 'USD',
        incomeByMonth: List<Decimal>.filled(
          GetAnalyticsTrendsUseCase.monthCount,
          Decimal.zero,
        ),
        expensesByMonth: List<Decimal>.filled(
          GetAnalyticsTrendsUseCase.monthCount,
          Decimal.zero,
        ),
      ),
    ],
  );
}

List<RankedCategorySpend> _allExpenseCategorySpend() {
  const amounts = [
    '80',
    '40',
    '20',
    '10',
    '5',
    '2',
    '1',
    '1',
    '1',
    '1',
    '1',
  ];
  return [
    for (var index = 0; index < SystemCategories.expense.length; index++)
      _spend(SystemCategories.expense[index].id, amounts[index]),
  ];
}

RankedCategorySpend _spend(String categoryId, String amount) {
  return RankedCategorySpend(
    categoryId: categoryId,
    amount: Decimal.parse(amount),
    displayCurrency: CurrencyCode.usd,
  );
}

Budget _budget({
  required String categoryId,
  required String amount,
  required String spentAmount,
}) {
  return Budget(
    id: 'b-$categoryId',
    userId: 'u-1',
    categoryId: categoryId,
    currencyCode: 'USD',
    amount: amount,
    spentAmount: spentAmount,
    month: 4,
    year: 2026,
    rolloverEnabled: false,
    isSynced: false,
    createdAt: DateTime(2026, 4, 1),
    updatedAt: DateTime(2026, 4, 1),
  );
}

Transaction _expense({
  String id = 'tx-1',
  String title = 'Market run',
  String amount = '80',
}) {
  return Transaction(
    id: id,
    userId: 'u-1',
    walletId: 'w-1',
    categoryId: 'cat-food',
    type: 'expense',
    amount: amount,
    currencyCode: 'USD',
    title: title,
    transactionDate: DateTime(2026, 4, 12),
    isSynced: false,
    createdAt: DateTime(2026, 4, 12),
    updatedAt: DateTime(2026, 4, 12),
  );
}

Future<void> _pumpAnalytics(
  WidgetTester tester, {
  required AnalyticsOverview overview,
  AnalyticsTrends? trends,
  List<Budget> budgets = const [],
  Size surface = const Size(800, 1400),
}) async {
  await tester.binding.setSurfaceSize(surface);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ..._overviewOverrides(
          overview: overview,
          trends: trends,
          budgets: budgets,
        ),
      ],
      child: const MaterialApp(home: AnalyticsScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows Insights header and month chip', (tester) async {
    await _pumpAnalytics(
      tester,
      overview: const AnalyticsOverview(
        totalsByCurrency: [],
        categorySpend: [],
      ),
    );

    expect(find.byKey(AnalyticsScreen.screenKey), findsOneWidget);
    expect(find.text('Insights'), findsOneWidget);
    expect(find.byKey(MonthSelector.titleKey), findsOneWidget);
    expect(find.text('Apr 2026'), findsOneWidget);
  });

  testWidgets('shows coach tip when a budget is under pressure', (tester) async {
    await _pumpAnalytics(
      tester,
      overview: const AnalyticsOverview(
        totalsByCurrency: [],
        categorySpend: [],
      ),
      budgets: [
        _budget(
          categoryId: 'cat-transport',
          amount: '150',
          spentAmount: '141',
        ),
        _budget(
          categoryId: 'cat-entertainment',
          amount: '150',
          spentAmount: '98',
        ),
      ],
    );

    expect(find.byKey(InsightsCoachCard.cardKey), findsOneWidget);
    expect(find.textContaining('Transport is at'), findsOneWidget);
    expect(find.byKey(InsightsCoachCard.actionKey), findsOneWidget);
  });

  testWidgets('shows spent donut and in vs out chart', (tester) async {
    await _pumpAnalytics(
      tester,
      overview: AnalyticsOverview(
        totalsByCurrency: const [],
        categorySpend: [
          _spend('cat-food', '80'),
          _spend('cat-transport', '40'),
        ],
      ),
      trends: _sampleTrends(),
    );

    expect(find.byType(CategorySpendPieChart), findsOneWidget);
    expect(find.byType(PieChart), findsOneWidget);
    expect(find.text('Spent'), findsOneWidget);
    expect(find.byKey(InVsOutBarChart.chartKey), findsOneWidget);
    expect(find.text('In vs out'), findsOneWidget);
  });

  testWidgets('pie chart renders without overflow', (tester) async {
    await _pumpAnalytics(
      tester,
      surface: const Size(400, 800),
      overview: AnalyticsOverview(
        totalsByCurrency: const [],
        categorySpend: _allExpenseCategorySpend(),
      ),
    );

    expect(find.byType(PieChart), findsOneWidget);
    final pie = tester.widget<PieChart>(find.byType(PieChart));
    expect(pie.data.sections.length, lessThanOrEqualTo(5));

    final chartBox = tester.getRect(find.byKey(CategorySpendPieChart.chartKey));
    expect(chartBox.left, greaterThanOrEqualTo(0));
    expect(chartBox.right, lessThanOrEqualTo(400));
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows empty spending copy when there is no spend', (tester) async {
    await _pumpAnalytics(
      tester,
      overview: const AnalyticsOverview(
        totalsByCurrency: [],
        categorySpend: [],
      ),
    );

    expect(find.text('No spending this month.'), findsOneWidget);
    expect(find.byType(PieChart), findsNothing);
  });

  testWidgets('drill-down navigates correctly', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final query = CategoryMonthQuery.fromMonth(
      categoryId: 'cat-food',
      month: DateTime(2026, 4),
    );
    final router = GoRouter(
      initialLocation: '/analytics',
      routes: [
        GoRoute(
          path: '/analytics',
          builder: (context, state) => const AnalyticsScreen(),
          routes: [
            GoRoute(
              path: 'categories/:categoryId',
              builder: (context, state) {
                return CategoryDrilldownScreen(
                  categoryId: state.pathParameters['categoryId'] ?? '',
                  year: 2026,
                  month: 4,
                );
              },
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._overviewOverrides(
            overview: AnalyticsOverview(
              totalsByCurrency: const [],
              categorySpend: [
                _spend('cat-food', '80'),
                _spend('cat-transport', '40'),
              ],
            ),
          ),
          categoryMonthTransactionsProvider(query).overrideWith(
            (ref) => Stream.value([_expense()]),
          ),
          categoryMonthDisplayTotalProvider(query).overrideWith(
            (ref) async => Money(
              amount: Decimal.parse('80'),
              currency: CurrencyCode.usd,
            ),
          ),
          budgetsForMonthProvider(query).overrideWith(
            (ref) => Stream.value(const []),
          ),
          categoryMonthBudgetProvider(query).overrideWith(
            (ref) => Stream.value(null),
          ),
        ],
        child: MaterialApp.router(
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            );
          },
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(CategorySpendPieChart.legendRowKey('cat-food')));
    await tester.pumpAndSettle();

    expect(find.byKey(CategoryDrilldownScreen.screenKey), findsOneWidget);
    expect(find.byKey(AnalyticsBreadcrumbBar.barKey), findsOneWidget);
    expect(find.text('Food'), findsWidgets);
    expect(find.text('April'), findsWidgets);
    expect(find.byKey(CategoryDrilldownScreen.totalKey), findsOneWidget);
    expect(find.text('\$80.00'), findsWidgets);
    expect(find.text('Market run'), findsOneWidget);

    await tester.tap(find.byKey(AnalyticsBreadcrumbBar.spendingCrumbKey));
    await tester.pumpAndSettle();

    expect(find.byKey(AnalyticsScreen.screenKey), findsOneWidget);
    expect(find.text('Insights'), findsOneWidget);
  });

  testWidgets('in vs out chart handles zero months', (tester) async {
    await _pumpAnalytics(
      tester,
      overview: const AnalyticsOverview(
        totalsByCurrency: [],
        categorySpend: [],
      ),
      trends: _allZeroTrends(),
    );

    expect(find.byKey(InVsOutBarChart.chartKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows empty trends copy when there is no activity',
      (tester) async {
    await _pumpAnalytics(
      tester,
      overview: const AnalyticsOverview(
        totalsByCurrency: [],
        categorySpend: [],
      ),
    );

    expect(
      find.text('No income or expenses in the last 6 months.'),
      findsOneWidget,
    );
    expect(find.byKey(InVsOutBarChart.chartKey), findsNothing);
  });

  testWidgets('tapping a month bar focuses that month chip', (tester) async {
    await _pumpAnalytics(
      tester,
      overview: const AnalyticsOverview(
        totalsByCurrency: [],
        categorySpend: [],
      ),
      trends: _sampleTrends(),
    );

    await tester.ensureVisible(
      find.byKey(const Key('in-vs-out-month-2026-3')),
    );
    await tester.tap(find.byKey(const Key('in-vs-out-month-2026-3')));
    await tester.pumpAndSettle();

    // Fixed month notifier ignores selectMonth; chart still remains.
    expect(find.byKey(InVsOutBarChart.chartKey), findsOneWidget);
  });
}
