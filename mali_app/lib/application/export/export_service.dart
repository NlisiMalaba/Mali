import 'package:fpdart/fpdart.dart';
import 'package:mali_app/application/export/export_file_name.dart';
import 'package:mali_app/core/auth/auth_user_store.dart';
import 'package:mali_app/core/error/failure.dart';
import 'package:mali_app/core/logging/app_logger.dart';
import 'package:mali_app/domain/services/export_file_store.dart';
import 'package:mali_app/domain/services/export_renderer.dart';
import 'package:mali_app/domain/services/export_service.dart';
import 'package:mali_app/domain/usecases/build_transaction_export_usecase.dart';
import 'package:mali_app/domain/value_objects/date_range.dart';
import 'package:mali_app/domain/value_objects/export_filters.dart';
import 'package:mali_app/domain/value_objects/exported_file.dart';

/// Orchestrates exports: collect the data, render it, write it to disk.
///
/// Format-specific work lives in the injected [IExportRenderer]s, and storage
/// in [IExportFileStore], so adding a format does not change this class.
class ExportService implements IExportService {
  const ExportService({
    required BuildTransactionExportUseCase buildTransactionExport,
    required IExportRenderer pdfRenderer,
    required IExportRenderer csvRenderer,
    required IExportFileStore fileStore,
    required IAuthUserStore authUserStore,
    required IAppLogger logger,
    DateTime Function() clock = DateTime.now,
  })  : _buildTransactionExport = buildTransactionExport,
        _pdfRenderer = pdfRenderer,
        _csvRenderer = csvRenderer,
        _fileStore = fileStore,
        _authUserStore = authUserStore,
        _logger = logger,
        _clock = clock;

  final BuildTransactionExportUseCase _buildTransactionExport;
  final IExportRenderer _pdfRenderer;
  final IExportRenderer _csvRenderer;
  final IExportFileStore _fileStore;
  final IAuthUserStore _authUserStore;
  final IAppLogger _logger;
  final DateTime Function() _clock;

  @override
  Future<Either<Failure, ExportedFile>> exportToPdf(
    DateRange range, {
    ExportFilters filters = ExportFilters.none,
  }) {
    return _export(range: range, renderer: _pdfRenderer, filters: filters);
  }

  @override
  Future<Either<Failure, ExportedFile>> exportToCsv(
    DateRange range, {
    ExportFilters filters = ExportFilters.none,
  }) {
    return _export(range: range, renderer: _csvRenderer, filters: filters);
  }

  Future<Either<Failure, ExportedFile>> _export({
    required DateRange range,
    required IExportRenderer renderer,
    required ExportFilters filters,
  }) async {
    final user = await _authUserStore.readUser();
    if (user == null) {
      return const Left(
        AuthFailure(message: 'Sign in to export your transactions.'),
      );
    }

    final exportResult = await _buildTransactionExport(
      range: range,
      userName: user.name,
      generatedAt: _clock(),
      filters: filters,
    );
    final failure = exportResult.getLeft().toNullable();
    if (failure != null) {
      _logger.error('Export data collection failed: ${failure.message}');
      return Left(failure);
    }
    final export = exportResult.getOrElse(
      (_) => throw StateError('expected transaction export'),
    );

    try {
      final bytes = await renderer.render(export);
      final saved = await _fileStore.save(
        fileName: ExportFileName.forRange(
          range: range,
          extension: renderer.fileExtension,
        ),
        mimeType: renderer.mimeType,
        bytes: bytes,
      );

      _logger.info(
        'Exported ${export.rows.length} transactions to ${saved.fileName}.',
      );
      return Right(saved);
    } catch (error, stackTrace) {
      _logger.error(
        'Failed to write the ${renderer.fileExtension} export.',
        error: error,
        stackTrace: stackTrace,
      );
      return Left(
        StorageFailure(
          message: 'Could not save the export to your device.',
          cause: error,
        ),
      );
    }
  }
}
