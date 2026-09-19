/// Cadence for the weekly digest: every Sunday evening, local time.
class DigestSchedule {
  const DigestSchedule._();

  /// Local hour treated as "evening" for delivery.
  static const int deliveryHour = 18;

  static const Duration period = Duration(days: 7);

  /// The next Sunday [deliveryHour] strictly after [now].
  static DateTime nextDelivery(DateTime now) {
    final daysUntilSunday = DateTime.sunday - now.weekday;
    final candidate = DateTime(
      now.year,
      now.month,
      now.day + daysUntilSunday,
      deliveryHour,
    );

    if (candidate.isAfter(now)) {
      return candidate;
    }
    return DateTime(
      candidate.year,
      candidate.month,
      candidate.day + period.inDays,
      deliveryHour,
    );
  }

  /// Delay WorkManager should wait before the first digest run.
  static Duration initialDelay(DateTime now) {
    return nextDelivery(now).difference(now);
  }
}
