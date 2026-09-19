import 'package:decimal/decimal.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mali_app/application/models/category_month_query.dart';
import 'package:mali_app/application/models/home_monthly_summary_display.dart';
import 'package:mali_app/application/providers/analytics_providers.dart';
import 'package:mali_app/application/providers/home_providers.dart';
import 'package:mali_app/domain/entities/transaction.dart';
import 'package:mali_app/domain/usecases/get_analytics_overview_usecase.dart';
import 'package:mali_app/domain/usecases/get_analytics_trends_usecase.dart';
import 'package:mali_app/domain/usecases/get_monthly_summary_usecase.dart';
import 'package:mali_app/domain/value_objects/currency_code.dart';
import 'package:mali_app/domain/value_objects/money.dart';
import 'package:mali_app/presentation/constants/system_categories.dart';
import 'package:mali_app/presentation/models/analytics_tab.dart';
import 'package:mali_app/presentation/screens/analytics/analytics_screen.dart';
import 'package:mali_app/presentation/screens/analytics/category_drilldown_screen.dart';
import 'package:mali_app/presentation/widgets/analytics/analytics_breadcrumb_bar.dart';
import 'package:mali_app/presentation/widgets/analytics/category_spend_pie_chart.dart';
import 'package:mali_app/presentation/widgets/analytics/currency_net_table.dart';
import 'package:mali_app/presentation/widgets/analytics/income_expense_trends_chart.dart';
import 'package:mali_app/presentation/widgets/analytics/top_spending_categories_list.dart';
import 'package:mali_app/presentation/widgets/home/month_summary_card.dart';

List<dynamic> _overviewOverrides({
  required AnalyticsOverview overview,
  HomeMonthlySummaryDisplay? summary,
  AnalyticsTrends? trends,
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
  Size surface = const Size(800, 1400),
}) async {
  await tester.binding.setSurfaceSize(surface);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ..._overviewOverrides(overview: overview, trends: trends),
      ],
      child: const MaterialApp(home: AnalyticsScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openSpendingTab(WidgetTester tester) async {
  await tester.tap(find.byKey(AnalyticsTab.spending.tabKey));
  await tester.pumpAndSettle();
}

Future<void> _openTrendsTab(WidgetTester tester) async {
  await tester.tap(find.byKey(AnalyticsTab.trends.tabKey));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows Overview, Spending, and Trends tabs', (tester) async {
    await _pumpAnalytics(
      tester,
      overview: const AnalyticsOverview(
        totalsByCurrency: [],
        categorySpend: [],
      ),
    );

    expect(find.byKey(AnalyticsScreen.screenKey), findsOneWidget);
    expect(find.byKey(AnalyticsScreen.tabBarKey), findsOneWidget);
    expect(find.text('Analytics'), findsOneWidget);

    for (final tab in AnalyticsTab.values) {
      expect(find.byKey(tab.tabKey), findsOneWidget);
      expect(find.text(tab.label), findsOneWidget);
    }

    expect(
      DefaultTabController.of(tester.element(find.byType(TabBar))).index,
      AnalyticsTab.overview.index,
    );
    expect(find.byKey(AnalyticsTab.overview.panelKey), findsOneWidget);
  });

  testWidgets('switching tabs updates the selected tab', (tester) async {
    await _pumpAnalytics(
      tester,
      overview: const AnalyticsOverview(
        totalsByCurrency: [],
        categorySpend: [],
      ),
    );

    await tester.tap(find.byKey(AnalyticsTab.spending.tabKey));
    await tester.pumpAndSettle();

    expect(
      DefaultTabController.of(tester.element(find.byType(TabBar))).index,
      AnalyticsTab.spending.index,
    );

    await tester.tap(find.byKey(AnalyticsTab.trends.tabKey));
    await tester.pumpAndSettle();

    expect(
      DefaultTabController.of(tester.element(find.byType(TabBar))).index,
      AnalyticsTab.trends.index,
    );
  });

  testWidgets(
      'Overview shows month summary, currency net table, and top spending',
      (tester) async {
    await _pumpAnalytics(
      tester,
      overview: AnalyticsOverview(
        totalsByCurrency: [
          CurrencyMonthlyTotals(
            currencyCode: 'USD',
            income: Decimal.parse('200'),
            expenses: Decimal.parse('80'),
          ),
          CurrencyMonthlyTotals(
            currencyCode: 'ZAR',
            income: Decimal.parse('50'),
            expenses: Decimal.parse('10'),
          ),
        ],
        categorySpend: [
          _spend('cat-food', '80'),
          _spend('cat-transport', '40'),
        ],
      ),
    );

    expect(find.byType(MonthSummaryCard), findsOneWidget);
    expect(find.byKey(CurrencyNetTable.tableKey), findsOneWidget);
    expect(find.byKey(CurrencyNetTable.rowKey('USD')), findsOneWidget);
    expect(find.byKey(CurrencyNetTable.rowKey('ZAR')), findsOneWidget);
    expect(find.text('By currency'), findsOneWidget);
    expect(find.text('Top spending'), findsOneWidget);
    expect(find.text('1. Food'), findsOneWidget);
    expect(find.text('2. Transport'), findsOneWidget);
    expect(find.byKey(TopSpendingCategoriesList.listKey), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(TopSpendingCategoriesList.listKey),
        matching: find.byType(LinearProgressIndicator),
      ),
      findsNWidgets(2),
    );
  });

  testWidgets('pie chart renders without overflow', (tester) async {
    await _pumpAnalytics(
      tester,
      surface: const Size(360, 700),
      overview: AnalyticsOverview(
        totalsByCurrency: const [],
        categorySpend: _allExpenseCategorySpend(),
      ),
    );

    await _openSpendingTab(tester);

    expect(find.byType(PieChart), findsOneWidget);
    final pie = tester.widget<PieChart>(find.byType(PieChart));
    expect(pie.data.sections.length, SystemCategories.expense.length);

    final chartBox = tester.getRect(find.byKey(CategorySpendPieChart.chartKey));
    expect(chartBox.left, greaterThanOrEqualTo(0));
    expect(chartBox.right, lessThanOrEqualTo(360));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Spending tab shows an empty state when there is no spend',
      (tester) async {
    await _pumpAnalytics(
      tester,
      overview: const AnalyticsOverview(
        totalsByCurrency: [],
        categorySpend: [],
      ),
    );

    await _openSpendingTab(tester);

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
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await _openSpendingTab(tester);
    await tester.tap(find.byKey(CategorySpendPieChart.legendRowKey('cat-food')));
    await tester.pumpAndSettle();

    expect(find.byKey(CategoryDrilldownScreen.screenKey), findsOneWidget);
    expect(find.byKey(AnalyticsBreadcrumbBar.barKey), findsOneWidget);
    expect(find.text('Food'), findsWidgets);
    expect(find.text('April 2026'), findsWidgets);
    expect(find.byKey(CategoryDrilldownScreen.totalKey), findsOneWidget);
    expect(find.text('USD 80.00'), findsWidgets);
    expect(find.text('Market run'), findsOneWidget);

    await tester.tap(find.byKey(AnalyticsBreadcrumbBar.spendingCrumbKey));
    await tester.pumpAndSettle();

    expect(find.byKey(AnalyticsScreen.screenKey), findsOneWidget);
    expect(
      DefaultTabController.of(tester.element(find.byType(TabBar))).index,
      AnalyticsTab.spending.index,
    );
  });

  testWidgets('line chart handles months with zero transactions',
      (tester) async {
    await _pumpAnalytics(
      tester,
      overview: const AnalyticsOverview(
        totalsByCurrency: [],
        categorySpend: [],
      ),
      trends: _allZeroTrends(),
    );

    await _openTrendsTab(tester);

    expect(find.byType(LineChart), findsOneWidget);
    final chart = tester.widget<LineChart>(find.byType(LineChart));
    expect(chart.data.lineBarsData.length, 2);
    for (final bar in chart.data.lineBarsData) {
      expect(bar.spots.length, GetAnalyticsTrendsUseCase.monthCount);
      expect(bar.spots.every((spot) => spot.y == 0), isTrue);
    }
    expect(chart.data.maxY, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Trends tab shows an empty state when there is no activity',
      (tester) async {
    await _pumpAnalytics(
      tester,
      overview: const AnalyticsOverview(
        totalsByCurrency: [],
        categorySpend: [],
      ),
    );

    await _openTrendsTab(tester);

    expect(
      find.text('No income or expenses in the last 6 months.'),
      findsOneWidget,
    );
    expect(find.byType(LineChart), findsNothing);
  });

  testWidgets('toggling a currency hides its trend lines', (tester) async {
    await _pumpAnalytics(
      tester,
      overview: const AnalyticsOverview(
        totalsByCurrency: [],
        categorySpend: [],
      ),
      trends: _sampleTrends(),
    );

    await _openTrendsTab(tester);
    await tester.tap(
      find.byKey(IncomeExpenseTrendsChart.currencyToggleKey('ZAR')),
    );
    await tester.pumpAndSettle();

    final chart = tester.widget<LineChart>(find.byType(LineChart));
    expect(chart.data.lineBarsData.length, 2);
  });

  testWidgets('tapping a trend month shows that month summary card',
      (tester) async {
    await _pumpAnalytics(
      tester,
      overview: const AnalyticsOverview(
        totalsByCurrency: [],
        categorySpend: [],
      ),
      trends: _sampleTrends(),
    );

    await _openTrendsTab(tester);
    await tester.ensureVisible(
      find.byKey(IncomeExpenseTrendsChart.monthPointKey(DateTime(2026, 3))),
    );
    await tester.tap(
      find.byKey(IncomeExpenseTrendsChart.monthPointKey(DateTime(2026, 3))),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MonthSummaryCard), findsWidgets);
    expect(find.text('March 2026'), findsWidgets);
  });
}
