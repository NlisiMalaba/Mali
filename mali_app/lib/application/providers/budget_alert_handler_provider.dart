import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mali_app/application/budget/budget_alert_handler.dart';
import 'package:mali_app/application/providers/app_preferences_provider.dart';
import 'package:mali_app/application/providers/notification_providers.dart';
import 'package:mali_app/application/providers/use_case_providers.dart';

final budgetAlertHandlerProvider = Provider<void>((ref) {
  final handler = BudgetAlertHandler(
    notificationService: ref.watch(notificationServiceProvider),
  );
  final eventBus = ref.watch(budgetExceededEventBusProvider);

  final subscription = eventBus.stream.listen((event) {
    if (!ref.read(appPreferencesProvider).budgetAlertsEnabled) {
      return;
    }
    unawaited(handler.handle(event));
  });

  ref.onDispose(subscription.cancel);
});
