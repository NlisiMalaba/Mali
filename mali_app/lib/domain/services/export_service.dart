import 'package:fpdart/fpdart.dart';
import 'package:mali_app/core/error/failure.dart';
import 'package:mali_app/domain/value_objects/date_range.dart';
import 'package:mali_app/domain/value_objects/export_filters.dart';
import 'package:mali_app/domain/value_objects/exported_file.dart';

abstract interface class IExportService {
  /// Renders the transactions in [range] to a PDF and saves it to the
  /// device's downloads location.
  Future<Either<Failure, ExportedFile>> exportToPdf(
    DateRange range, {
    ExportFilters filters = ExportFilters.none,
  });

  /// Renders the transactions in [range] to a CSV and saves it to the
  /// device's downloads location.
  Future<Either<Failure, ExportedFile>> exportToCsv(
    DateRange range, {
    ExportFilters filters = ExportFilters.none,
  });
}
