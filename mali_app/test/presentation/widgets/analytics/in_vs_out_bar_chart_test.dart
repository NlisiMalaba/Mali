import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mali_app/domain/usecases/get_analytics_trends_usecase.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/widgets/analytics/in_vs_out_bar_chart.dart';

void main() {
  test('In vs out uses green income and red expense colors', () {
    expect(InVsOutBarChart.inColor, AppColors.income);
    expect(InVsOutBarChart.outColor, AppColors.expense);
  });

  testWidgets('legend and bars use income green and expense red', (tester) async {
    final months = [
      for (var month = 1; month <= 6; month++) DateTime(2026, month),
    ];
    final trends = AnalyticsTrends(
      months: months,
      currencies: [
        CurrencyTrendSeries(
          currencyCode: 'USD',
          incomeByMonth: [
            for (var i = 0; i < 6; i++) Decimal.parse('${(i + 1) * 10}'),
          ],
          expensesByMonth: [
            for (var i = 0; i < 6; i++) Decimal.parse('${(i + 1) * 5}'),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InVsOutBarChart(
            trends: trends,
            currencyCode: 'USD',
          ),
        ),
      ),
    );

    expect(find.text('In'), findsOneWidget);
    expect(find.text('Out'), findsOneWidget);

    final coloredBars = tester
        .widgetList<Container>(find.byType(Container))
        .where((container) {
          final decoration = container.decoration;
          return decoration is BoxDecoration &&
              (decoration.color == AppColors.income ||
                  decoration.color == AppColors.expense);
        })
        .toList();

    expect(
      coloredBars.any((bar) => (bar.decoration! as BoxDecoration).color == AppColors.income),
      isTrue,
    );
    expect(
      coloredBars.any((bar) => (bar.decoration! as BoxDecoration).color == AppColors.expense),
      isTrue,
    );
  });
}
