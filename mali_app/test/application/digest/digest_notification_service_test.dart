import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mali_app/application/digest/digest_notification_service.dart';
import 'package:mali_app/application/digest/digest_schedule.dart';
import 'package:mali_app/core/error/failure.dart';
import 'package:mali_app/core/logging/app_logger.dart';
import 'package:mali_app/core/notifications/notification_service.dart';
import 'package:mali_app/domain/usecases/build_weekly_digest_usecase.dart';
import 'package:mali_app/domain/value_objects/currency_code.dart';
import 'package:mali_app/domain/value_objects/date_range.dart';
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

class _StubBuildWeeklyDigestUseCase implements BuildWeeklyDigestUseCase {
  _StubBuildWeeklyDigestUseCase(this._result);

  final Either<Failure, WeeklyDigest> _result;
  DateTime? lastNow;
  CurrencyCode? lastDisplayCurrency;

  @override
  Future<Either<Failure, WeeklyDigest>> call({
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

class _RecordingScheduler implements WorkmanagerScheduler {
  Duration? lastInitialDelay;

  @override
  Future<void> registerWeeklyDigest({required Duration initialDelay}) async {
    lastInitialDelay = initialDelay;
  }
}

WeeklyDigest _digest({
  int expenseCount = 2,
  DigestGoalProgress? goal,
}) {
  return WeeklyDigest(
    window: DateRange(
      start: DateTime(2026, 9, 14),
      end: DateTime(2026, 9, 20, 23, 59, 59),
    ),
    totalSpent: Money(
      amount: Decimal.parse('80'),
      currency: CurrencyCode.usd,
    ),
    expenseCount: expenseCount,
    topCategory: DigestCategorySpend(
      categoryId: 'cat-food',
      amount: Money(amount: Decimal.parse('50'), currency: CurrencyCode.usd),
    ),
    topGoal: goal,
  );
}

({
  DigestNotificationService service,
  _FakeNotificationService notifications,
  _RecordingLogger logger,
  _RecordingScheduler scheduler,
  _StubBuildWeeklyDigestUseCase buildDigest,
}) _harness({
  required Either<Failure, WeeklyDigest> result,
  DateTime? now,
}) {
  final notifications = _FakeNotificationService();
  final logger = _RecordingLogger();
  final scheduler = _RecordingScheduler();
  final buildDigest = _StubBuildWeeklyDigestUseCase(result);
  final clockValue = now ?? DateTime(2026, 9, 20, 18);

  return (
    service: DigestNotificationService(
      buildWeeklyDigest: buildDigest,
      notificationService: notifications,
      logger: logger,
      displayCurrency: CurrencyCode.usd,
      scheduler: scheduler,
      clock: () => clockValue,
    ),
    notifications: notifications,
    logger: logger,
    scheduler: scheduler,
    buildDigest: buildDigest,
  );
}

void main() {
  group('DigestNotificationService.registerWeeklyDigest', () {
    test('schedules using the delay until the next Sunday evening', () async {
      // Wednesday morning.
      final now = DateTime(2026, 9, 16, 10);
      final harness = _harness(result: right(_digest()), now: now);

      await harness.service.registerWeeklyDigest();

      expect(
        harness.scheduler.lastInitialDelay,
        DigestSchedule.initialDelay(now),
      );
    });
  });

  group('DigestNotificationService.deliverDigest', () {
    test('shows the digest notification', () async {
      final harness = _harness(
        result: right(
          _digest(
            goal: const DigestGoalProgress(
              goalId: 'g-1',
              name: 'Emergency Fund',
              percentFunded: 40,
            ),
          ),
        ),
      );

      final result = await harness.service.deliverDigest();

      expect(result.status, DigestDeliveryStatus.delivered);
      expect(harness.notifications.shown, hasLength(1));
      expect(harness.notifications.shown.single.title, 'Your weekly digest');
      expect(
        harness.notifications.shown.single.body,
        'You spent USD 80.00 this week. Food was your biggest expense. '
        'Your Emergency Fund is 40% funded.',
      );
    });

    test('reuses a stable notification id so digests replace each other',
        () async {
      final harness = _harness(result: right(_digest()));

      await harness.service.deliverDigest();

      expect(
        harness.notifications.shown.single.id,
        DigestNotificationService.notificationId,
      );
    });

    test('passes the configured display currency and clock to the use case',
        () async {
      final now = DateTime(2026, 9, 20, 18, 30);
      final harness = _harness(result: right(_digest()), now: now);

      await harness.service.deliverDigest();

      expect(harness.buildDigest.lastNow, now);
      expect(harness.buildDigest.lastDisplayCurrency, CurrencyCode.usd);
    });

    test('skips delivery when there is no activity and no goal', () async {
      final harness = _harness(
        result: right(_digest(expenseCount: 0)),
      );

      final result = await harness.service.deliverDigest();

      expect(result.status, DigestDeliveryStatus.skippedEmpty);
      expect(harness.notifications.shown, isEmpty);
      expect(harness.logger.infos, hasLength(1));
    });

    test('logs and reports failure when the digest cannot be built', () async {
      final harness = _harness(
        result: left(const StorageFailure(message: 'db gone')),
      );

      final result = await harness.service.deliverDigest();

      expect(result.status, DigestDeliveryStatus.failed);
      expect(result.isSuccess, isFalse);
      expect(harness.notifications.shown, isEmpty);
      expect(harness.logger.errors.single, contains('db gone'));
    });

    test('logs and reports failure when the notification cannot be shown',
        () async {
      final harness = _harness(result: right(_digest()));
      harness.notifications.error = StateError('no permission');

      final result = await harness.service.deliverDigest();

      expect(result.status, DigestDeliveryStatus.failed);
      expect(harness.logger.errors, hasLength(1));
    });
  });
}
