import 'package:mali_app/application/digest/digest_schedule.dart';
import 'package:mali_app/application/digest/weekly_digest_messages.dart';
import 'package:mali_app/core/logging/app_logger.dart';
import 'package:mali_app/core/notifications/notification_ids.dart';
import 'package:mali_app/core/notifications/notification_service.dart';
import 'package:mali_app/domain/usecases/build_weekly_digest_usecase.dart';
import 'package:mali_app/domain/value_objects/currency_code.dart';
import 'package:workmanager/workmanager.dart';

const String weeklyDigestTaskName = 'maliWeeklyDigest';
const String weeklyDigestUniqueName = 'mali-weekly-digest';

/// Schedules and delivers the Sunday-evening spending digest.
///
/// Registration and delivery are separate so the background isolate can invoke
/// [deliverDigest] without re-registering the periodic task.
class DigestNotificationService {
  DigestNotificationService({
    required BuildWeeklyDigestUseCase buildWeeklyDigest,
    required INotificationService notificationService,
    required IAppLogger logger,
    required CurrencyCode displayCurrency,
    WorkmanagerScheduler? scheduler,
    DateTime Function() clock = DateTime.now,
  })  : _buildWeeklyDigest = buildWeeklyDigest,
        _notificationService = notificationService,
        _logger = logger,
        _displayCurrency = displayCurrency,
        _scheduler = scheduler ?? const WorkmanagerScheduler(),
        _clock = clock;

  /// Stable id so a new digest replaces the previous week's notification.
  static const int notificationId = NotificationIds.weeklyDigest;

  final BuildWeeklyDigestUseCase _buildWeeklyDigest;
  final INotificationService _notificationService;
  final IAppLogger _logger;
  final CurrencyCode _displayCurrency;
  final WorkmanagerScheduler _scheduler;
  final DateTime Function() _clock;

  Future<void> registerWeeklyDigest() {
    final now = _clock();
    return _scheduler.registerWeeklyDigest(
      initialDelay: DigestSchedule.initialDelay(now),
    );
  }

  Future<DigestDeliveryResult> deliverDigest() async {
    final now = _clock();
    final result = await _buildWeeklyDigest(
      now: now,
      displayCurrency: _displayCurrency,
    );

    final failure = result.getLeft().toNullable();
    if (failure != null) {
      _logger.error('Weekly digest build failed: ${failure.message}');
      return DigestDeliveryResult.failed(failure.message);
    }

    final digest = result.getOrElse(
      (_) => throw StateError('expected weekly digest'),
    );
    if (digest.hasNothingToReport) {
      _logger.info('Weekly digest skipped: no activity and no active goals.');
      return const DigestDeliveryResult.skipped();
    }

    final body = WeeklyDigestMessages.notificationBody(digest);
    try {
      await _notificationService.show(
        id: notificationId,
        title: WeeklyDigestMessages.notificationTitle,
        body: body,
      );
    } catch (error, stackTrace) {
      _logger.error(
        'Weekly digest notification could not be shown.',
        error: error,
        stackTrace: stackTrace,
      );
      return DigestDeliveryResult.failed('Notification delivery failed.');
    }

    return DigestDeliveryResult.delivered(body);
  }
}

/// Thin seam over the WorkManager plugin so the service stays unit-testable.
class WorkmanagerScheduler {
  const WorkmanagerScheduler();

  Future<void> registerWeeklyDigest({required Duration initialDelay}) {
    return Workmanager().registerPeriodicTask(
      weeklyDigestUniqueName,
      weeklyDigestTaskName,
      frequency: DigestSchedule.period,
      initialDelay: initialDelay,
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  }
}

class DigestDeliveryResult {
  const DigestDeliveryResult._({
    required this.status,
    this.body,
    this.message,
  });

  const DigestDeliveryResult.delivered(String body)
      : this._(status: DigestDeliveryStatus.delivered, body: body);

  const DigestDeliveryResult.skipped()
      : this._(status: DigestDeliveryStatus.skippedEmpty);

  const DigestDeliveryResult.failed(String message)
      : this._(status: DigestDeliveryStatus.failed, message: message);

  final DigestDeliveryStatus status;
  final String? body;
  final String? message;

  bool get isSuccess => status != DigestDeliveryStatus.failed;
}

enum DigestDeliveryStatus {
  delivered,
  skippedEmpty,
  failed,
}
