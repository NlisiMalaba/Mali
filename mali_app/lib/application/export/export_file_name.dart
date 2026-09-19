import 'package:intl/intl.dart';
import 'package:mali_app/domain/value_objects/date_range.dart';

/// Builds predictable, filesystem-safe names for exported documents.
class ExportFileName {
  const ExportFileName._();

  static const String prefix = 'mali-transactions';

  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  /// Example: `mali-transactions_2026-09-01_2026-09-30.pdf`.
  ///
  /// Deterministic for a given range, so re-exporting replaces the previous
  /// file instead of accumulating copies.
  static String forRange({
    required DateRange range,
    required String extension,
  }) {
    final start = _dateFormat.format(range.start);
    final end = _dateFormat.format(range.end);
    return '${prefix}_${start}_$end.$extension';
  }
}
