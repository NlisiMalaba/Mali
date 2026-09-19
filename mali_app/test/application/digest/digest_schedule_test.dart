import 'package:flutter_test/flutter_test.dart';
import 'package:mali_app/application/digest/digest_schedule.dart';

void main() {
  group('DigestSchedule', () {
    test('targets the coming Sunday evening from a weekday', () {
      // Wednesday 2026-09-16, mid-morning.
      final now = DateTime(2026, 9, 16, 10, 30);

      expect(
        DigestSchedule.nextDelivery(now),
        DateTime(2026, 9, 20, DigestSchedule.deliveryHour),
      );
    });

    test('targets today when it is Sunday before the delivery hour', () {
      final now = DateTime(2026, 9, 20, 9);

      expect(
        DigestSchedule.nextDelivery(now),
        DateTime(2026, 9, 20, DigestSchedule.deliveryHour),
      );
    });

    test('rolls to next Sunday once the delivery hour has passed', () {
      final now = DateTime(2026, 9, 20, DigestSchedule.deliveryHour, 1);

      expect(
        DigestSchedule.nextDelivery(now),
        DateTime(2026, 9, 27, DigestSchedule.deliveryHour),
      );
    });

    test('rolls across a month boundary', () {
      // Sunday 2026-09-27 at 20:00 -> Sunday 2026-10-04.
      final now = DateTime(2026, 9, 27, 20);

      expect(
        DigestSchedule.nextDelivery(now),
        DateTime(2026, 10, 4, DigestSchedule.deliveryHour),
      );
    });

    test('initialDelay is the gap until the next delivery', () {
      final now = DateTime(2026, 9, 20, 16);

      expect(DigestSchedule.initialDelay(now), const Duration(hours: 2));
    });

    test('initialDelay is never negative', () {
      for (var weekday = 1; weekday <= 7; weekday++) {
        final now = DateTime(2026, 9, 13 + weekday, 23, 59);
        expect(
          DigestSchedule.initialDelay(now).isNegative,
          isFalse,
          reason: 'weekday ${now.weekday} produced a negative delay',
        );
      }
    });
  });
}
