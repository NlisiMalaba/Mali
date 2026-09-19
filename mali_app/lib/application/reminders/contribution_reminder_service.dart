import 'package:mali_app/application/reminders/contribution_reminder_messages.dart';
import 'package:mali_app/application/reminders/contribution_reminder_schedule.dart';
import 'package:mali_app/core/logging/app_logger.dart';
import 'package:mali_app/core/notifications/notification_ids.dart';
import 'package:mali_app/core/notifications/notification_service.dart';
import 'package:mali_app/domain/usecases/build_contribution_reminder_usecase.dart';
import 'package:mali_app/domain/value_objects/currency_code.dart';
import 'package:workmanager/workmanager.dart';

const String contributionReminderTaskName = 'maliContributionReminder';
const String contributionReminderUniqueName = 'mali-contribution-reminder';

/// Schedules and delivers the monthly "allocate your surplus" prompt.
///
/// WorkManager cannot express "the 1st of every month" as a fixed interval, so
/// each run schedules the following one via [runScheduledReminder].
class ContributionReminderService {
  ContributionReminderService({
    required BuildContributionReminderUseCase buildContributionReminder,
    required INotificationService notificationService,
    required IAppLogger logger,
    required CurrencyCode displayCurrency,
    ReminderScheduler? scheduler,
    DateTime Function() clock = DateTime.now,
  })  : _buildContributionReminder = buildContributionReminder,
        _notificationService = notificationService,
        _logger = logger,
        _displayCurrency = displayCurrency,
        _scheduler = scheduler ?? const ReminderScheduler(),
        _clock = clock;

  /// Stable id so each month's prompt replaces the previous one.
  static const int notificationId = NotificationIds.contributionReminder;

  final BuildContributionReminderUseCase _buildContributionReminder;
  final INotificationService _notificationService;
  final IAppLogger _logger;
  final CurrencyCode _displayCurrency;
  final ReminderScheduler _scheduler;
  final DateTime Function() _clock;

  /// Ensures a reminder is pending without disturbing one already queued.
  /// Safe to call on every app start.
  Future<void> scheduleNextReminder() {
    return _schedule(replaceExisting: false);
  }

  /// Entry point for the background task: deliver this month's prompt, then
  /// queue next month's.
  Future<ReminderDeliveryResult> runScheduledReminder() async {
    final result = await deliverReminder();
    await _rescheduleAfterRun();
    return result;
  }

  Future<ReminderDeliveryResult> deliverReminder() async {
    final result = await _buildContributionReminder(
      now: _clock(),
      displayCurrency: _displayCurrency,
    );

    final failure = result.getLeft().toNullable();
    if (failure != null) {
      _logger.error('Contribution reminder build failed: ${failure.message}');
      return ReminderDeliveryResult.failed(failure.message);
    }

    final reminder = result.getOrElse(
      (_) => throw StateError('expected contribution reminder'),
    );
    final goal = reminder.topGoal;
    if (!reminder.shouldPrompt || goal == null) {
      _logger.info('Contribution reminder skipped: no surplus or no goal.');
      return const ReminderDeliveryResult.skipped();
    }

    final body = ContributionReminderMessages.notificationBody(
      surplus: reminder.surplus,
      month: reminder.month,
      goalName: goal.name,
    );

    try {
      await _notificationService.show(
        id: notificationId,
        title: ContributionReminderMessages.notificationTitle,
        body: body,
      );
    } catch (error, stackTrace) {
      _logger.error(
        'Contribution reminder notification could not be shown.',
        error: error,
        stackTrace: stackTrace,
      );
      return ReminderDeliveryResult.failed('Notification delivery failed.');
    }

    return ReminderDeliveryResult.delivered(body);
  }

  /// A rescheduling error must not fail the task, or WorkManager would retry
  /// the delivery and prompt the user twice.
  Future<void> _rescheduleAfterRun() async {
    try {
      await _schedule(replaceExisting: true);
    } catch (error, stackTrace) {
      _logger.error(
        'Failed to schedule next contribution reminder.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _schedule({required bool replaceExisting}) {
    return _scheduler.scheduleReminder(
      initialDelay: ContributionReminderSchedule.initialDelay(_clock()),
      replaceExisting: replaceExisting,
    );
  }
}

/// Thin seam over the WorkManager plugin so the service stays unit-testable.
class ReminderScheduler {
  const ReminderScheduler();

  Future<void> scheduleReminder({
    required Duration initialDelay,
    required bool replaceExisting,
  }) {
    return Workmanager().registerOneOffTask(
      contributionReminderUniqueName,
      contributionReminderTaskName,
      initialDelay: initialDelay,
      existingWorkPolicy:
          replaceExisting ? ExistingWorkPolicy.replace : ExistingWorkPolicy.keep,
    );
  }
}

class ReminderDeliveryResult {
  const ReminderDeliveryResult._({
    required this.status,
    this.body,
    this.message,
  });

  const ReminderDeliveryResult.delivered(String body)
      : this._(status: ReminderDeliveryStatus.delivered, body: body);

  const ReminderDeliveryResult.skipped()
      : this._(status: ReminderDeliveryStatus.skippedNoSurplus);

  const ReminderDeliveryResult.failed(String message)
      : this._(status: ReminderDeliveryStatus.failed, message: message);

  final ReminderDeliveryStatus status;
  final String? body;
  final String? message;

  bool get isSuccess => status != ReminderDeliveryStatus.failed;
}

enum ReminderDeliveryStatus {
  delivered,
  skippedNoSurplus,
  failed,
}
