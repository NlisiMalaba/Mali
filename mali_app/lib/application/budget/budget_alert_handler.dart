import 'package:mali_app/application/budget/budget_alert_messages.dart';
import 'package:mali_app/core/notifications/notification_service.dart';
import 'package:mali_app/domain/events/budget_exceeded_event.dart';

class BudgetAlertHandler {
  const BudgetAlertHandler({
    required INotificationService notificationService,
  }) : _notificationService = notificationService;

  final INotificationService _notificationService;

  Future<void> handle(BudgetExceededEvent event) async {
    final categoryName = BudgetAlertMessages.categoryName(event.budget.categoryId);
    final body = BudgetAlertMessages.notificationBody(
      categoryName: categoryName,
      event: event,
    );

    await _notificationService.show(
      id: event.budget.id.hashCode,
      title: BudgetAlertMessages.notificationTitle,
      body: body,
    );
  }
}
