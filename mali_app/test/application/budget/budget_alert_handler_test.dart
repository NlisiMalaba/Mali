import 'package:flutter_test/flutter_test.dart';
import 'package:mali_app/application/budget/budget_alert_handler.dart';
import 'package:mali_app/core/notifications/notification_service.dart';
import 'package:mali_app/domain/entities/budget.dart';
import 'package:mali_app/domain/events/budget_exceeded_event.dart';

class _FakeNotificationService implements INotificationService {
  final shown = <({int id, String title, String body})>[];

  @override
  Future<void> initialize() async {}

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async {
    shown.add((id: id, title: title, body: body));
  }
}

Budget _budget() {
  final now = DateTime(2026, 5, 1);
  return Budget(
    id: 'b-1',
    userId: 'u-1',
    categoryId: 'cat-food',
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
  group('BudgetAlertHandler', () {
    test('shows local notification for 80% budget warning', () async {
      final notifications = _FakeNotificationService();
      final handler = BudgetAlertHandler(notificationService: notifications);

      await handler.handle(
        BudgetExceededEvent(
          budget: _budget(),
          thresholdRatio: BudgetExceededEvent.warningThresholdRatio,
        ),
      );

      expect(notifications.shown, hasLength(1));
      expect(notifications.shown.single.title, 'Budget alert');
      expect(
        notifications.shown.single.body,
        "You've used 80% of your Food budget this month",
      );
    });
  });
}
