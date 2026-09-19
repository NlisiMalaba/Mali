import 'package:mali_app/application/digest/digest_notification_service.dart';
import 'package:mali_app/application/providers/display_currency_provider.dart';
import 'package:mali_app/application/providers/logging_providers.dart';
import 'package:mali_app/application/providers/notification_providers.dart';
import 'package:mali_app/application/providers/use_case_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'digest_providers.g.dart';

@Riverpod(keepAlive: true)
DigestNotificationService digestNotificationService(Ref ref) {
  return DigestNotificationService(
    buildWeeklyDigest: ref.watch(buildWeeklyDigestUseCaseProvider),
    notificationService: ref.watch(notificationServiceProvider),
    logger: ref.watch(appLoggerProvider),
    displayCurrency: ref.watch(displayCurrencyProvider),
  );
}
