import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mali_app/application/budget/budget_alert_handler.dart';
import 'package:mali_app/application/providers/use_case_providers.dart';
import 'package:mali_app/core/notifications/local_notification_service.dart';
import 'package:mali_app/core/notifications/notification_service.dart';

final notificationServiceProvider = Provider<INotificationService>((ref) {
  return LocalNotificationService.instance;
});

final budgetAlertHandlerProvider = Provider<void>((ref) {
  final handler = BudgetAlertHandler(
    notificationService: ref.watch(notificationServiceProvider),
  );
  final eventBus = ref.watch(budgetExceededEventBusProvider);

  final subscription = eventBus.stream.listen((event) {
    unawaited(handler.handle(event));
  });

  ref.onDispose(subscription.cancel);
});
