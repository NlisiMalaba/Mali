import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mali_app/application/export/export_request.dart';
import 'package:mali_app/application/providers/export_controller.dart';
import 'package:mali_app/application/providers/export_providers.dart';
import 'package:mali_app/application/providers/logging_providers.dart';
import 'package:mali_app/core/error/failure.dart';
import 'package:mali_app/core/logging/app_logger.dart';
import 'package:mali_app/domain/services/export_service.dart';
import 'package:mali_app/domain/services/file_share_service.dart';
import 'package:mali_app/domain/value_objects/date_range.dart';
import 'package:mali_app/domain/value_objects/export_filters.dart';
import 'package:mali_app/domain/value_objects/export_format.dart';
import 'package:mali_app/domain/value_objects/exported_file.dart';

class _FakeExportService implements IExportService {
  _FakeExportService(this._result);

  final Either<Failure, ExportedFile> _result;
  DateRange? lastRange;
  ExportFilters? lastFilters;
  ExportFormat? lastFormat;

  @override
  Future<Either<Failure, ExportedFile>> exportToPdf(
    DateRange range, {
    ExportFilters filters = ExportFilters.none,
  }) async {
    lastRange = range;
    lastFilters = filters;
    lastFormat = ExportFormat.pdf;
    return _result;
  }

  @override
  Future<Either<Failure, ExportedFile>> exportToCsv(
    DateRange range, {
    ExportFilters filters = ExportFilters.none,
  }) async {
    lastRange = range;
    lastFilters = filters;
    lastFormat = ExportFormat.csv;
    return _result;
  }
}

class _FakeFileShareService implements IFileShareService {
  ExportedFile? lastFile;
  Object? error;

  @override
  Future<void> shareFile(ExportedFile file) async {
    if (error != null) {
      throw error!;
    }
    lastFile = file;
  }
}

class _RecordingLogger implements IAppLogger {
  final errors = <String>[];

  @override
  void info(String message) {}

  @override
  void warning(String message, {Object? error}) {}

  @override
  void error(String message, {Object? error, StackTrace? stackTrace}) {
    errors.add(message);
  }
}

final _range = DateRange(
  start: DateTime(2026, 9, 1),
  end: DateTime(2026, 9, 30, 23, 59, 59),
);

const _file = ExportedFile(
  path: '/downloads/mali-transactions_2026-09-01_2026-09-30.pdf',
  fileName: 'mali-transactions_2026-09-01_2026-09-30.pdf',
  mimeType: 'application/pdf',
  byteCount: 12,
);

void main() {
  late _FakeExportService exportService;
  late _FakeFileShareService shareService;
  late _RecordingLogger logger;
  late ProviderContainer container;

  final request = ExportRequest(
    range: _range,
    format: ExportFormat.pdf,
    filters: const ExportFilters(walletId: 'w-1'),
  );

  setUp(() {
    exportService = _FakeExportService(right(_file));
    shareService = _FakeFileShareService();
    logger = _RecordingLogger();
    container = ProviderContainer(
      overrides: [
        exportServiceProvider.overrideWithValue(exportService),
        fileShareServiceProvider.overrideWithValue(shareService),
        appLoggerProvider.overrideWithValue(logger),
      ],
    );
  });

  tearDown(() => container.dispose());

  group('ExportController', () {
    test('exports as PDF, then opens the share sheet', () async {
      await container.read(exportControllerProvider.notifier).submit(request);

      expect(exportService.lastFormat, ExportFormat.pdf);
      expect(exportService.lastRange, _range);
      expect(exportService.lastFilters?.walletId, 'w-1');
      expect(shareService.lastFile, _file);
      expect(container.read(exportControllerProvider).value, _file);
    });

    test('exports as CSV when that format is selected', () async {
      await container.read(exportControllerProvider.notifier).submit(
            ExportRequest(range: _range, format: ExportFormat.csv),
          );

      expect(exportService.lastFormat, ExportFormat.csv);
    });

    test('surfaces a failure without sharing', () async {
      container.dispose();
      exportService = _FakeExportService(
        left(const StorageFailure(message: 'disk full')),
      );
      container = ProviderContainer(
        overrides: [
          exportServiceProvider.overrideWithValue(exportService),
          fileShareServiceProvider.overrideWithValue(shareService),
          appLoggerProvider.overrideWithValue(logger),
        ],
      );

      await container.read(exportControllerProvider.notifier).submit(request);

      expect(container.read(exportControllerProvider).hasError, isTrue);
      expect(shareService.lastFile, isNull);
    });

    test('still reports success when the share sheet fails', () async {
      shareService.error = StateError('share unavailable');

      await container.read(exportControllerProvider.notifier).submit(request);

      expect(container.read(exportControllerProvider).value, _file);
      expect(logger.errors, hasLength(1));
    });
  });

  group('exportErrorMessage', () {
    test('uses the failure message when one is available', () {
      expect(
        exportErrorMessage(const StorageFailure(message: 'disk full')),
        'disk full',
      );
    });
  });
}
