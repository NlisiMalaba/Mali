import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/widgets/budget/budget_bar.dart';

LinearProgressIndicator _progressIndicator(WidgetTester tester) {
  return tester.widget<LinearProgressIndicator>(
    find.byType(LinearProgressIndicator),
  );
}

Future<void> _pumpBudgetBar(
  WidgetTester tester, {
  required double usage,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: BudgetBar(key: ValueKey(usage), usage: usage),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('BudgetBar', () {
    testWidgets('uses green below 80% usage', (tester) async {
      await _pumpBudgetBar(tester, usage: 0.5);

      expect(_progressIndicator(tester).color, AppColors.success);
      expect(_progressIndicator(tester).value, 0.5);
    });

    testWidgets('uses amber at 80% usage', (tester) async {
      await _pumpBudgetBar(tester, usage: 0.8);

      expect(_progressIndicator(tester).color, AppColors.warning);
      expect(_progressIndicator(tester).value, 0.8);
    });

    testWidgets('uses red at 100% usage', (tester) async {
      await _pumpBudgetBar(tester, usage: 1);

      expect(_progressIndicator(tester).color, AppColors.error);
      expect(_progressIndicator(tester).value, 1);
    });

    testWidgets('clamps usage above 100% for display', (tester) async {
      await _pumpBudgetBar(tester, usage: 1.4);

      expect(_progressIndicator(tester).color, AppColors.error);
      expect(_progressIndicator(tester).value, 1);
    });

    testWidgets('animates when usage changes', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BudgetBar(usage: 0.2),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(_progressIndicator(tester).value, 0.2);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BudgetBar(usage: 0.9),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 175));

      final midValue = _progressIndicator(tester).value!;
      expect(midValue, greaterThan(0.2));
      expect(midValue, lessThan(0.9));

      await tester.pumpAndSettle();

      expect(_progressIndicator(tester).value, 0.9);
      expect(_progressIndicator(tester).color, AppColors.warning);
    });
  });
}
