import 'package:intl/intl.dart';

/// Formats a transaction date for list section headers: Today, Yesterday, or "Mon 5 Jan".
String formatTransactionDateGroupHeader(
  DateTime date, {
  DateTime? referenceNow,
}) {
  final now = referenceNow ?? DateTime.now();
  final localDate = DateTime(date.year, date.month, date.day);
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));

  if (localDate == today) {
    return 'Today';
  }
  if (localDate == yesterday) {
    return 'Yesterday';
  }

  return DateFormat('EEE d MMM').format(localDate);
}
