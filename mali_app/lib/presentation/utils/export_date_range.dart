import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mali_app/domain/value_objects/date_range.dart';

/// Converts between the calendar dates a date-range picker uses and the
/// inclusive [DateRange] the export query expects.
class ExportDateRange {
  const ExportDateRange._();

  static final DateFormat labelFormat = DateFormat('d MMM yyyy');

  /// How far back the picker lets the user go.
  static const int lookbackYears = 5;

  /// The calendar month containing [now], from the 1st through today.
  static DateRange currentMonth(DateTime now) {
    return DateRange(
      start: DateTime(now.year, now.month, 1),
      end: _endOfDay(now),
    );
  }

  /// Maps a picker selection onto a query range that includes the whole of
  /// the last chosen day.
  static DateRange fromPicker(DateTimeRange picked) {
    return DateRange(
      start: DateTime(picked.start.year, picked.start.month, picked.start.day),
      end: _endOfDay(picked.end),
    );
  }

  /// Calendar dates only, so the picker does not inherit a 23:59:59 end.
  static DateTimeRange toPicker(DateRange range) {
    return DateTimeRange(
      start: DateTime(range.start.year, range.start.month, range.start.day),
      end: DateTime(range.end.year, range.end.month, range.end.day),
    );
  }

  static String label(DateRange range) {
    return '${labelFormat.format(range.start)} – ${labelFormat.format(range.end)}';
  }

  static DateTime firstPickerDate(DateTime now) {
    return DateTime(now.year - lookbackYears, now.month, now.day);
  }

  static DateTime lastPickerDate(DateTime now) {
    return DateTime(now.year, now.month, now.day);
  }

  static DateTime _endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999, 999);
  }
}
