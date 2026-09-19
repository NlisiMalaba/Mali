/// Cadence for the contribution reminder: the 1st of each month, local time.
///
/// Calendar months vary in length, so this is delivered as a self-rescheduling
/// one-off task rather than a fixed-interval periodic one.
class ContributionReminderSchedule {
  const ContributionReminderSchedule._();

  /// Local hour on the 1st at which the reminder fires.
  static const int deliveryHour = 9;

  static const int _firstDayOfMonth = 1;

  /// The next 1st-of-the-month [deliveryHour] strictly after [now].
  static DateTime nextDelivery(DateTime now) {
    final thisMonth = DateTime(
      now.year,
      now.month,
      _firstDayOfMonth,
      deliveryHour,
    );
    if (thisMonth.isAfter(now)) {
      return thisMonth;
    }
    return DateTime(now.year, now.month + 1, _firstDayOfMonth, deliveryHour);
  }

  /// Delay WorkManager should wait before the next reminder run.
  static Duration initialDelay(DateTime now) {
    return nextDelivery(now).difference(now);
  }
}
