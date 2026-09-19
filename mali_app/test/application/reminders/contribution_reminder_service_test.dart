import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mali_app/application/reminders/contribution_reminder_schedule.dart';
import 'package:mali_app/application/reminders/contribution_reminder_service.dart';
import 'package:mali_app/core/error/failure.dart';
import 'package:mali_app/core/logging/app_logger.dart';
import 'package:mali_app/core/notifications/notification_service.dart';
import 'package:mali_app/domain/usecases/build_contribution_reminder_usecase.dart';
import 'package:mali_app/domain/value_objects/currency_code.dart';
import 'package:mali_app/domain/value_objects/money.dart';

class _FakeNotificationService implements INotificationService {
  final shown = <({int id, String title, String body})>[];
  Object? error;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async {
    if (error != null) {
      throw error!;
    }
    shown.add((id: id, title: title, body: body));
  }
}

class _RecordingLogger implements IAppLogger {
  final infos = <String>[];
  final warnings = <String>[];
  final errors = <String>[];

  @override
  void info(String message) => infos.add(message);

  @override
  void warning(String message, {Object? error}) => warnings.add(message);

  @override
  void error(String message, {Object? error, StackTrace? stackTrace}) =>
      errors.add(message);
}

class _StubBuildContributionReminderUseCase
    implements BuildContributionReminderUseCase {
  _StubBuildContributionReminderUseCase(this._result);

  final Either<Failure, ContributionReminder> _result;
  DateTime? lastNow;
  CurrencyCode? lastDisplayCurrency;

  @override
  Future<Either<Failure, ContributionReminder>> call({
    required DateTime now,
    required CurrencyCode displayCurrency,
  }) async {
    lastNow = now;
    lastDisplayCurrency = displayCurrency;
    return _result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RecordingScheduler implements ReminderScheduler {
  final calls = <({Duration initialDelay, bool replaceExisting})>[];
  Object? error;

  @override
  Future<void> scheduleReminder({
    required Duration initialDelay,
    required bool replaceExisting,
  }) async {
    if (error != null) {
      throw error!;
    }
    calls.add((initialDelay: initialDelay, replaceExisting: replaceExisting));
  }
}

ContributionReminder _reminder({
  String surplus = '749.75',
  String? goalName = 'Emergency Fund',
}) {
  return ContributionReminder(
    month: DateTime(2026, 9),
    surplus: Money(
      amount: Decimal.parse(surplus),
      currency: CurrencyCode.usd,
    ),
    topGoal: goalName == null
        ? null
        : ReminderGoal(goalId: 'g-1', name: goalName, percentFunded: 25),
  );
}

({
  ContributionReminderService service,
  _FakeNotificationService notifications,
  _RecordingLogger logger,
  _RecordingScheduler scheduler,
  _StubBuildContributionReminderUseCase buildReminder,
}) _harness({
  required Either<Failure, ContributionReminder> result,
  DateTime? now,
}) {
  final notifications = _FakeNotificationService();
  final logger = _RecordingLogger();
  final scheduler = _RecordingScheduler();
  final buildReminder = _StubBuildContributionReminderUseCase(result);
  final clockValue = now ?? DateTime(2026, 10, 1, 9);

  return (
    service: ContributionReminderService(
      buildContributionReminder: buildReminder,
      notificationService: notifications,
      logger: logger,
      displayCurrency: CurrencyCode.usd,
      scheduler: scheduler,
      clock: () => clockValue,
    ),
    notifications: notifications,
    logger: logger,
    scheduler: scheduler,
    buildReminder: buildReminder,
  );
}

void main() {
  group('ContributionReminderService.scheduleNextReminder', () {
    test('queues the next 1st of the month without replacing pending work',
        () async {
      final now = DateTime(2026, 9, 17, 14);
      final harness = _harness(result: right(_reminder()), now: now);

      await harness.service.scheduleNextReminder();

      expect(harness.scheduler.calls, hasLength(1));
      expect(
        harness.scheduler.calls.single.initialDelay,
        ContributionReminderSchedule.initialDelay(now),
      );
      expect(harness.scheduler.calls.single.replaceExisting, isFalse);
    });
  });

  group('ContributionReminderService.deliverReminder', () {
    test('prompts with the surplus, month and top goal', () async {
      final harness = _harness(result: right(_reminder()));

      final result = await harness.service.deliverReminder();

      expect(result.status, ReminderDeliveryStatus.delivered);
      expect(harness.notifications.shown, hasLength(1));
      expect(
        harness.notifications.shown.single.body,
        'You had a USD 749.75 surplus in September. '
        'Allocate to your Emergency Fund?',
      );
      expect(
        harness.notifications.shown.single.id,
        ContributionReminderService.notificationId,
      );
    });

    test('passes the configured display currency and clock to the use case',
        () async {
      final now = DateTime(2026, 10, 1, 9, 30);
      final harness = _harness(result: right(_reminder()), now: now);

      await harness.service.deliverReminder();

      expect(harness.buildReminder.lastNow, now);
      expect(harness.buildReminder.lastDisplayCurrency, CurrencyCode.usd);
    });

    test('stays silent when there was no surplus', () async {
      final harness = _harness(result: right(_reminder(surplus: '-20')));

      final result = await harness.service.deliverReminder();

      expect(result.status, ReminderDeliveryStatus.skippedNoSurplus);
      expect(harness.notifications.shown, isEmpty);
    });

    test('stays silent when there is no goal to fund', () async {
      final harness = _harness(result: right(_reminder(goalName: null)));

      final result = await harness.service.deliverReminder();

      expect(result.status, ReminderDeliveryStatus.skippedNoSurplus);
      expect(harness.notifications.shown, isEmpty);
    });

    test('logs and reports failure when the reminder cannot be built',
        () async {
      final harness = _harness(
        result: left(const StorageFailure(message: 'db gone')),
      );

      final result = await harness.service.deliverReminder();

      expect(result.status, ReminderDeliveryStatus.failed);
      expect(harness.notifications.shown, isEmpty);
      expect(harness.logger.errors.single, contains('db gone'));
    });

    test('logs and reports failure when the notification cannot be shown',
        () async {
      final harness = _harness(result: right(_reminder()));
      harness.notifications.error = StateError('no permission');

      final result = await harness.service.deliverReminder();

      expect(result.status, ReminderDeliveryStatus.failed);
      expect(harness.logger.errors, hasLength(1));
    });
  });

  group('ContributionReminderService.runScheduledReminder', () {
    test('queues next month after delivering', () async {
      final harness = _harness(result: right(_reminder()));

      final result = await harness.service.runScheduledReminder();

      expect(result.status, ReminderDeliveryStatus.delivered);
      expect(harness.scheduler.calls, hasLength(1));
      expect(harness.scheduler.calls.single.replaceExisting, isTrue);
    });

    test('queues next month even when nothing was delivered', () async {
      final harness = _harness(result: right(_reminder(surplus: '0')));

      await harness.service.runScheduledReminder();

      expect(harness.scheduler.calls, hasLength(1));
    });

    test('reports delivery success even if rescheduling fails', () async {
      final harness = _harness(result: right(_reminder()));
      harness.scheduler.error = StateError('scheduler unavailable');

      final result = await harness.service.runScheduledReminder();

      expect(result.status, ReminderDeliveryStatus.delivered);
      expect(harness.logger.errors, hasLength(1));
    });
  });
}
