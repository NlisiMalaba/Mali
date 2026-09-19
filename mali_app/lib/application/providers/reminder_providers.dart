import 'package:mali_app/application/providers/display_currency_provider.dart';
import 'package:mali_app/application/providers/logging_providers.dart';
import 'package:mali_app/application/providers/notification_providers.dart';
import 'package:mali_app/application/providers/use_case_providers.dart';
import 'package:mali_app/application/reminders/contribution_reminder_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reminder_providers.g.dart';

@Riverpod(keepAlive: true)
ContributionReminderService contributionReminderService(Ref ref) {
  return ContributionReminderService(
    buildContributionReminder:
        ref.watch(buildContributionReminderUseCaseProvider),
    notificationService: ref.watch(notificationServiceProvider),
    logger: ref.watch(appLoggerProvider),
    displayCurrency: ref.watch(displayCurrencyProvider),
  );
}
