import 'package:mali_app/domain/events/budget_exceeded_event.dart';

abstract interface class IBudgetExceededEventPublisher {
  void publish(BudgetExceededEvent event);
}
