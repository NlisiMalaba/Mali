import 'package:decimal/decimal.dart';
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
import 'package:mali_app/domain/value_objects/currency_code.dart';
import 'package:mali_app/domain/value_objects/money.dart';
import 'package:mali_app/presentation/models/analytics_tab.dart';
import 'package:mali_app/presentation/screens/analytics/analytics_screen.dart';
import 'package:mali_app/presentation/screens/analytics/category_drilldown_screen.dart';
import 'package:mali_app/presentation/widgets/analytics/analytics_breadcrumb_bar.dart';

Transaction _expense({
  String id = 'tx-1',
  String title = 'Market run',
  String amount = '45',
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

// Return type is inferred: Riverpod 3 does not export `Override`, so the
// element type cannot be written explicitly.
_drilldownOverrides({
  List<Transaction> transactions = const [],
  String total = '0',
}) {
  final query = CategoryMonthQuery.fromMonth(
    categoryId: 'cat-food',
    month: DateTime(2026, 4),
  );
  return [
    homeSelectedMonthProvider.overrideWith(
      () => _FixedMonth(DateTime(2026, 4)),
    ),
    homeMonthlySummaryDisplayProvider.overrideWith(
      (ref) async => HomeMonthlySummaryDisplay(
        month: DateTime(2026, 4),
        income: Decimal.zero,
        expenses: Decimal.parse(total),
        displayCurrency: CurrencyCode.usd,
      ),
    ),
    analyticsOverviewProvider.overrideWith(
      (ref) async => const AnalyticsOverview(
        totalsByCurrency: [],
        categorySpend: [],
      ),
    ),
    analyticsTrendsProvider.overrideWith(
      (ref) async => AnalyticsTrends(
        months: GetAnalyticsTrendsUseCase.monthsEndingAt(DateTime(2026, 4)),
        currencies: const [],
      ),
    ),
    categoryMonthTransactionsProvider(query).overrideWith(
      (ref) => Stream.value(transactions),
    ),
    categoryMonthDisplayTotalProvider(query).overrideWith(
      (ref) async => Money(
        amount: Decimal.parse(total),
        currency: CurrencyCode.usd,
      ),
    ),
  ];
}

class _FixedMonth extends HomeSelectedMonth {
  _FixedMonth(this.month);

  final DateTime month;

  @override
  DateTime build() => DateTime(month.year, month.month);
}

GoRouter _router({String initialLocation = '/analytics/categories/cat-food'}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/analytics',
        builder: (context, state) => AnalyticsScreen(
          initialTab: AnalyticsScreen.tabFromQuery(
            state.uri.queryParameters[AnalyticsScreen.tabQuery],
          ),
        ),
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
}

Future<void> _pumpDrilldown(
  WidgetTester tester, {
  List<Transaction> transactions = const [],
  String total = '0',
  String initialLocation = '/analytics/categories/cat-food?year=2026&month=4',
}) async {
  await tester.binding.setSurfaceSize(const Size(800, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: _drilldownOverrides(
        transactions: transactions,
        total: total,
      ),
      child: MaterialApp.router(
        routerConfig: _router(initialLocation: initialLocation),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows breadcrumb, month total, and category transactions',
      (tester) async {
    await _pumpDrilldown(
      tester,
      transactions: [
        _expense(),
        _expense(id: 'tx-2', title: 'Lunch', amount: '35'),
      ],
      total: '80',
    );

    expect(find.byKey(CategoryDrilldownScreen.screenKey), findsOneWidget);
    expect(find.byKey(AnalyticsBreadcrumbBar.barKey), findsOneWidget);
    expect(find.byKey(AnalyticsBreadcrumbBar.analyticsCrumbKey), findsOneWidget);
    expect(find.byKey(AnalyticsBreadcrumbBar.spendingCrumbKey), findsOneWidget);
    expect(find.byKey(AnalyticsBreadcrumbBar.categoryCrumbKey), findsOneWidget);
    expect(find.text('Food'), findsWidgets);
    expect(find.text('April 2026'), findsOneWidget);
    expect(find.byKey(CategoryDrilldownScreen.totalKey), findsOneWidget);
    expect(find.text('USD 80.00'), findsOneWidget);
    expect(find.text('Market run'), findsOneWidget);
    expect(find.text('Lunch'), findsOneWidget);
  });

  testWidgets('shows an empty state when the category has no transactions',
      (tester) async {
    await _pumpDrilldown(tester);

    expect(find.text('No transactions in this category.'), findsOneWidget);
    expect(find.text('USD 0.00'), findsOneWidget);
  });

  testWidgets('Analytics breadcrumb opens the Analytics screen', (tester) async {
    await _pumpDrilldown(tester, transactions: [_expense()], total: '45');

    await tester.tap(find.byKey(AnalyticsBreadcrumbBar.analyticsCrumbKey));
    await tester.pumpAndSettle();

    expect(find.byKey(AnalyticsScreen.screenKey), findsOneWidget);
    expect(find.byKey(CategoryDrilldownScreen.screenKey), findsNothing);
    expect(
      DefaultTabController.of(tester.element(find.byType(TabBar))).index,
      AnalyticsTab.overview.index,
    );
  });

  testWidgets('Spending breadcrumb opens the Spending tab', (tester) async {
    await _pumpDrilldown(tester, transactions: [_expense()], total: '45');

    await tester.tap(find.byKey(AnalyticsBreadcrumbBar.spendingCrumbKey));
    await tester.pumpAndSettle();

    expect(find.byKey(AnalyticsScreen.screenKey), findsOneWidget);
    expect(find.byKey(CategoryDrilldownScreen.screenKey), findsNothing);
    expect(
      DefaultTabController.of(tester.element(find.byType(TabBar))).index,
      AnalyticsTab.spending.index,
    );
  });
}
