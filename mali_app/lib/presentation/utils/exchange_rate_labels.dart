class ExchangeRateLabels {
  const ExchangeRateLabels._();

  static String lastUpdated(DateTime updatedAt, DateTime now) {
    final difference = now.difference(updatedAt);
    if (difference.inMinutes < 1) {
      return 'Exchange rates last updated: just now';
    }
    if (difference.inHours < 1) {
      final minutes = difference.inMinutes;
      return 'Exchange rates last updated: $minutes '
          '${minutes == 1 ? 'minute' : 'minutes'} ago';
    }
    if (difference.inHours < 24) {
      final hours = difference.inHours;
      return 'Exchange rates last updated: $hours '
          '${hours == 1 ? 'hour' : 'hours'} ago';
    }
    final days = difference.inDays;
    return 'Exchange rates last updated: $days '
        '${days == 1 ? 'day' : 'days'} ago';
  }
}
