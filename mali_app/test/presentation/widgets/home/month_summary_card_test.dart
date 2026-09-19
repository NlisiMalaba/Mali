import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mali_app/application/models/home_monthly_summary_display.dart';
import 'package:mali_app/application/providers/home_providers.dart';
import 'package:mali_app/domain/value_objects/currency_code.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/widgets/home/month_summary_card.dart';

class _FixedSelectedMonth extends HomeSelectedMonth {
  _FixedSelectedMonth(this.initialMonth);

  final DateTime initialMonth;

  @override
  DateTime build() => DateTime(initialMonth.year, initialMonth.month);
}

HomeMonthlySummaryDisplay _summary({
  required DateTime month,
  required String income,
  required String expenses,
}) {
  return HomeMonthlySummaryDisplay(
    month: month,
    income: Decimal.parse(income),
    expenses: Decimal.parse(expenses),
    displayCurrency: CurrencyCode.usd,
  );
}

Future<void> _pumpMonthSummaryCard(
  WidgetTester tester, {
  required HomeMonthlySummaryDisplay summary,
  DateTime? selectedMonth,
}) async {
  final month = selectedMonth ?? summary.month;

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        homeSelectedMonthProvider.overrideWith(
          () => _FixedSelectedMonth(month),
        ),
        homeMonthlySummaryDisplayProvider.overrideWith(
          (ref) async => summary,
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(body: MonthSummaryCard()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('MonthSummaryCard', () {
    testWidgets('shows surplus in green when income exceeds expenses',
        (tester) async {
      await _pumpMonthSummaryCard(
        tester,
        summary: _summary(
          month: DateTime(2026, 5),
          income: '1200',
          expenses: '800',
        ),
      );

      expect(find.text('Surplus'), findsOneWidget);
      expect(find.text('USD 400.00'), findsOneWidget);

      final amountText = tester.widget<Text>(
        find.byKey(MonthSummaryCard.netAmountKey),
      );
      expect(amountText.style?.color, AppColors.success);
    });

    testWidgets('shows deficit in red when expenses exceed income',
        (tester) async {
      await _pumpMonthSummaryCard(
        tester,
        summary: _summary(
          month: DateTime(2026, 5),
          income: '500',
          expenses: '900',
        ),
      );

      expect(find.text('Deficit'), findsOneWidget);
      expect(find.text('USD 400.00'), findsOneWidget);

      final amountText = tester.widget<Text>(
        find.byKey(MonthSummaryCard.netAmountKey),
      );
      expect(amountText.style?.color, AppColors.error);
    });

    testWidgets('month navigation changes displayed month', (tester) async {
      final may = DateTime(2026, 5);
      final april = DateTime(2026, 4);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homeSelectedMonthProvider.overrideWith(
              () => _FixedSelectedMonth(may),
            ),
            homeMonthlySummaryDisplayProvider.overrideWith(
              (ref) async {
                final selectedMonth = ref.watch(homeSelectedMonthProvider);
                return _summary(
                  month: selectedMonth,
                  income: '100',
                  expenses: '50',
                );
              },
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: MonthSummaryCard()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(DateFormat.yMMMM().format(may)),
        findsOneWidget,
      );

      await tester.tap(find.byKey(MonthSummaryCard.previousMonthKey));
      await tester.pumpAndSettle();

      expect(
        find.text(DateFormat.yMMMM().format(april)),
        findsOneWidget,
      );
      expect(
        find.text(DateFormat.yMMMM().format(may)),
        findsNothing,
      );
    });

    testWidgets('shows monthly summary metrics and legend', (tester) async {
      await _pumpMonthSummaryCard(
        tester,
        summary: _summary(
          month: DateTime(2026, 5),
          income: '1000',
          expenses: '600',
        ),
      );

      expect(find.text('Monthly Summary'), findsOneWidget);
      expect(find.text('INCOME'), findsOneWidget);
      expect(find.text('EXPENSES'), findsOneWidget);
      expect(find.text('SAVINGS RATE'), findsOneWidget);
      expect(find.text('BURN RATE'), findsOneWidget);
    });
  });
}
