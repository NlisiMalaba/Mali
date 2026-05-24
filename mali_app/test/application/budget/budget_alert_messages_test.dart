import 'package:flutter_test/flutter_test.dart';
import 'package:mali_app/application/budget/budget_alert_messages.dart';
import 'package:mali_app/domain/entities/budget.dart';
import 'package:mali_app/domain/events/budget_exceeded_event.dart';

Budget _budget({String categoryId = 'cat-food'}) {
  final now = DateTime(2026, 5, 1);
  return Budget(
    id: 'b-1',
    userId: 'u-1',
    categoryId: categoryId,
    currencyCode: 'USD',
    amount: '100',
    spentAmount: '80',
    month: 5,
    year: 2026,
    rolloverEnabled: false,
    isSynced: false,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('BudgetAlertMessages', () {
    test('resolves category name from system categories', () {
      expect(BudgetAlertMessages.categoryName('cat-food'), 'Food');
      expect(BudgetAlertMessages.categoryName('unknown'), 'Budget');
    });

    test('formats 80% warning notification body', () {
      final event = BudgetExceededEvent(
        budget: _budget(),
        thresholdRatio: BudgetExceededEvent.warningThresholdRatio,
      );

      expect(
        BudgetAlertMessages.notificationBody(
          categoryName: 'Food',
          event: event,
        ),
        "You've used 80% of your Food budget this month",
      );
    });

    test('formats 100% exceeded notification body', () {
      final event = BudgetExceededEvent(
        budget: _budget(),
        thresholdRatio: BudgetExceededEvent.exceededThresholdRatio,
      );

      expect(
        BudgetAlertMessages.notificationBody(
          categoryName: 'Food',
          event: event,
        ),
        "You've reached your Food budget limit this month",
      );
    });
  });
}
