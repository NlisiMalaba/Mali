/// Stable notification ids, kept together so recurring notifications replace
/// their own previous entry without colliding with each other.
class NotificationIds {
  const NotificationIds._();

  static const int weeklyDigest = 1001;
  static const int contributionReminder = 1002;
}
