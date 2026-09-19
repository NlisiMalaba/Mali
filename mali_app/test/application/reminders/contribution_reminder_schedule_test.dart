import 'package:flutter_test/flutter_test.dart';
import 'package:mali_app/application/reminders/contribution_reminder_schedule.dart';

void main() {
  const hour = ContributionReminderSchedule.deliveryHour;

  group('ContributionReminderSchedule', () {
    test('targets the 1st of next month from mid-month', () {
      final now = DateTime(2026, 9, 17, 14);

      expect(
        ContributionReminderSchedule.nextDelivery(now),
        DateTime(2026, 10, 1, hour),
      );
    });

    test('targets today when it is the 1st before the delivery hour', () {
      final now = DateTime(2026, 10, 1, hour - 1);

      expect(
        ContributionReminderSchedule.nextDelivery(now),
        DateTime(2026, 10, 1, hour),
      );
    });

    test('rolls to next month once the delivery hour has passed', () {
      final now = DateTime(2026, 10, 1, hour, 1);

      expect(
        ContributionReminderSchedule.nextDelivery(now),
        DateTime(2026, 11, 1, hour),
      );
    });

    test('rolls across a year boundary', () {
      final now = DateTime(2026, 12, 20, 8);

      expect(
        ContributionReminderSchedule.nextDelivery(now),
        DateTime(2027, 1, 1, hour),
      );
    });

    test('handles short months without drifting', () {
      final now = DateTime(2027, 2, 28, 23, 59);

      expect(
        ContributionReminderSchedule.nextDelivery(now),
        DateTime(2027, 3, 1, hour),
      );
    });

    test('initialDelay is the gap until the next delivery', () {
      final now = DateTime(2026, 10, 1, hour - 2);

      expect(
        ContributionReminderSchedule.initialDelay(now),
        const Duration(hours: 2),
      );
    });

    test('initialDelay is never negative across a full month', () {
      for (var day = 1; day <= 31; day++) {
        final now = DateTime(2026, 10, day, 23, 59);
        expect(
          ContributionReminderSchedule.initialDelay(now).isNegative,
          isFalse,
          reason: 'day $day produced a negative delay',
        );
      }
    });
  });
}
