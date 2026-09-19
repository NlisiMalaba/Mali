import 'package:mali_app/domain/value_objects/date_range.dart';
import 'package:mali_app/domain/value_objects/export_filters.dart';
import 'package:mali_app/domain/value_objects/export_format.dart';

/// Everything the user chose on the export screen.
class ExportRequest {
  const ExportRequest({
    required this.range,
    required this.format,
    this.filters = ExportFilters.none,
  });

  final DateRange range;
  final ExportFormat format;
  final ExportFilters filters;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExportRequest &&
        other.range == range &&
        other.format == format &&
        other.filters == filters;
  }

  @override
  int get hashCode => Object.hash(range, format, filters);
}
