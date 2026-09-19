import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mali_app/domain/value_objects/date_range.dart';
import 'package:mali_app/presentation/utils/export_date_range.dart';

void main() {
  group('ExportDateRange', () {
    test('currentMonth runs from the 1st through the end of today', () {
      final range = ExportDateRange.currentMonth(DateTime(2026, 9, 19, 14, 30));

      expect(range.start, DateTime(2026, 9, 1));
      expect(range.end, DateTime(2026, 9, 19, 23, 59, 59, 999, 999));
    });

    test('fromPicker includes the whole of the last selected day', () {
      final range = ExportDateRange.fromPicker(
        DateTimeRange(
          start: DateTime(2026, 8, 1),
          end: DateTime(2026, 8, 31),
        ),
      );

      expect(range.start, DateTime(2026, 8, 1));
      expect(range.end, DateTime(2026, 8, 31, 23, 59, 59, 999, 999));
    });

    test('toPicker strips the time-of-day so the calendar stays on dates', () {
      final picked = ExportDateRange.toPicker(
        DateRange(
          start: DateTime(2026, 9, 1),
          end: DateTime(2026, 9, 19, 23, 59, 59, 999, 999),
        ),
      );

      expect(picked.start, DateTime(2026, 9, 1));
      expect(picked.end, DateTime(2026, 9, 19));
    });

    test('label uses a compact day-month-year form', () {
      expect(
        ExportDateRange.label(
          DateRange(
            start: DateTime(2026, 9, 1),
            end: DateTime(2026, 9, 19, 23, 59, 59),
          ),
        ),
        '1 Sep 2026 – 19 Sep 2026',
      );
    });
  });
}
