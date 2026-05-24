import 'dart:async';

import 'package:mali_app/domain/events/budget_exceeded_event.dart';
import 'package:mali_app/domain/services/budget_exceeded_event_publisher.dart';

/// Broadcasts budget threshold crossings for app-wide handling (e.g. notifications).
class BudgetExceededEventBus implements IBudgetExceededEventPublisher {
  BudgetExceededEventBus._();

  static final BudgetExceededEventBus instance = BudgetExceededEventBus._();

  final StreamController<BudgetExceededEvent> _controller =
      StreamController<BudgetExceededEvent>.broadcast();

  Stream<BudgetExceededEvent> get stream => _controller.stream;

  @override
  void publish(BudgetExceededEvent event) {
    if (!_controller.isClosed) {
      _controller.add(event);
    }
  }
}
