import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mali_app/application/export/export_file_name.dart';
import 'package:mali_app/application/export/export_service.dart';
import 'package:mali_app/core/auth/auth_user_store.dart';
import 'package:mali_app/core/error/failure.dart';
import 'package:mali_app/core/logging/app_logger.dart';
import 'package:mali_app/domain/entities/user.dart';
import 'package:mali_app/domain/services/export_file_store.dart';
import 'package:mali_app/domain/services/export_renderer.dart';
import 'package:mali_app/domain/usecases/build_transaction_export_usecase.dart';
import 'package:mali_app/domain/value_objects/date_range.dart';
import 'package:mali_app/domain/value_objects/export_filters.dart';
import 'package:mali_app/domain/value_objects/exported_file.dart';

class _StubAuthUserStore implements IAuthUserStore {
  _StubAuthUserStore(this._user);

  final User? _user;

  @override
  Future<User?> readUser() async => _user;

  @override
  Future<void> saveUser(User user) async {}

  @override
  Future<void> clearUser() async {}
}

class _RecordingLogger implements IAppLogger {
  final infos = <String>[];
  final errors = <String>[];

  @override
  void info(String message) => infos.add(message);

  @override
  void warning(String message, {Object? error}) {}

  @override
  void error(String message, {Object? error, StackTrace? stackTrace}) =>
      errors.add(message);
}

class _StubBuildTransactionExportUseCase
    implements BuildTransactionExportUseCase {
  _StubBuildTransactionExportUseCase(this._result);

  final Either<Failure, TransactionExport> _result;
  String? lastUserName;
  DateTime? lastGeneratedAt;
  DateRange? lastRange;
  ExportFilters? lastFilters;

  @override
  Future<Either<Failure, TransactionExport>> call({
    required DateRange range,
    required String userName,
    required DateTime generatedAt,
    ExportFilters filters = ExportFilters.none,
  }) async {
    lastRange = range;
    lastUserName = userName;
    lastGeneratedAt = generatedAt;
    lastFilters = filters;
    return _result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeRenderer implements IExportRenderer {
  _FakeRenderer({
    required this.fileExtension,
    required this.mimeType,
    required this.bytes,
    this.error,
  });

  @override
  final String fileExtension;

  @override
  final String mimeType;

  final List<int> bytes;
  final Object? error;
  TransactionExport? lastExport;

  @override
  Future<Uint8List> render(TransactionExport export) async {
    lastExport = export;
    if (error != null) {
      throw error!;
    }
    return Uint8List.fromList(bytes);
  }
}

class _FakeFileStore implements IExportFileStore {
  _FakeFileStore({this.error});

  final Object? error;
  String? lastFileName;
  String? lastMimeType;
  Uint8List? lastBytes;

  @override
  Future<ExportedFile> save({
    required String fileName,
    required String mimeType,
    required Uint8List bytes,
  }) async {
    if (error != null) {
      throw error!;
    }
    lastFileName = fileName;
    lastMimeType = mimeType;
    lastBytes = bytes;
    return ExportedFile(
      path: '/downloads/$fileName',
      fileName: fileName,
      mimeType: mimeType,
      byteCount: bytes.length,
    );
  }
}

final _range = DateRange(
  start: DateTime(2026, 9, 1),
  end: DateTime(2026, 9, 30, 23, 59, 59),
);

TransactionExport _export() {
  return TransactionExport(
    range: _range,
    userName: 'Tendai',
    generatedAt: DateTime(2026, 10, 1, 8),
    rows: const [],
    monthlySummaries: const [],
  );
}

({
  ExportService service,
  _FakeRenderer pdfRenderer,
  _FakeRenderer csvRenderer,
  _FakeFileStore fileStore,
  _RecordingLogger logger,
  _StubBuildTransactionExportUseCase buildExport,
}) _harness({
  Either<Failure, TransactionExport>? result,
  User? user,
  bool signedIn = true,
  Object? renderError,
  Object? saveError,
}) {
  final pdfRenderer = _FakeRenderer(
    fileExtension: 'pdf',
    mimeType: 'application/pdf',
    bytes: const [1, 2, 3, 4],
    error: renderError,
  );
  final csvRenderer = _FakeRenderer(
    fileExtension: 'csv',
    mimeType: 'text/csv',
    bytes: const [5, 6],
    error: renderError,
  );
  final fileStore = _FakeFileStore(error: saveError);
  final logger = _RecordingLogger();
  final buildExport = _StubBuildTransactionExportUseCase(
    result ?? right(_export()),
  );

  return (
    service: ExportService(
      buildTransactionExport: buildExport,
      pdfRenderer: pdfRenderer,
      csvRenderer: csvRenderer,
      fileStore: fileStore,
      authUserStore: _StubAuthUserStore(
        !signedIn
            ? null
            : user ??
                User(
                  id: 'u-1',
                  name: 'Tendai',
                  createdAt: DateTime(2026, 1, 1),
                ),
      ),
      logger: logger,
      clock: () => DateTime(2026, 10, 1, 8),
    ),
    pdfRenderer: pdfRenderer,
    csvRenderer: csvRenderer,
    fileStore: fileStore,
    logger: logger,
    buildExport: buildExport,
  );
}

void main() {
  group('ExportService.exportToPdf', () {
    test('renders and saves the export', () async {
      final harness = _harness();

      final result = await harness.service.exportToPdf(_range);

      final file = result.getOrElse((_) => throw StateError('expected right'));
      expect(file.fileName, 'mali-transactions_2026-09-01_2026-09-30.pdf');
      expect(file.mimeType, 'application/pdf');
      expect(file.byteCount, 4);
      expect(harness.fileStore.lastBytes, [1, 2, 3, 4]);
    });

    test('names the file from the requested range', () async {
      final harness = _harness();

      await harness.service.exportToPdf(_range);

      expect(
        harness.fileStore.lastFileName,
        ExportFileName.forRange(range: _range, extension: 'pdf'),
      );
    });

    test('forwards wallet and category filters to data collection', () async {
      final harness = _harness();
      const filters = ExportFilters(walletId: 'w-1', categoryId: 'cat-food');

      await harness.service.exportToPdf(_range, filters: filters);

      expect(harness.buildExport.lastFilters, filters);
    });

    test('labels the export with the signed-in user and current time',
        () async {
      final harness = _harness();

      await harness.service.exportToPdf(_range);

      expect(harness.buildExport.lastUserName, 'Tendai');
      expect(harness.buildExport.lastGeneratedAt, DateTime(2026, 10, 1, 8));
      expect(harness.buildExport.lastRange, _range);
    });

    test('fails when nobody is signed in', () async {
      final harness = _harness(signedIn: false);

      final result = await harness.service.exportToPdf(_range);

      expect(result.isLeft(), isTrue);
      expect(harness.fileStore.lastFileName, isNull);
    });

    test('propagates a data collection failure', () async {
      final harness = _harness(
        result: left(const StorageFailure(message: 'db gone')),
      );

      final result = await harness.service.exportToPdf(_range);

      expect(result.isLeft(), isTrue);
      expect(harness.logger.errors.single, contains('db gone'));
      expect(harness.fileStore.lastFileName, isNull);
    });

    test('reports a failure when rendering throws', () async {
      final harness = _harness(renderError: StateError('bad glyph'));

      final result = await harness.service.exportToPdf(_range);

      expect(result.isLeft(), isTrue);
      expect(harness.logger.errors, hasLength(1));
    });

    test('reports a failure when the file cannot be written', () async {
      final harness = _harness(saveError: StateError('disk full'));

      final result = await harness.service.exportToPdf(_range);

      expect(result.isLeft(), isTrue);
      expect(harness.logger.errors, hasLength(1));
    });
  });

  group('ExportService.exportToCsv', () {
    test('renders and saves through the csv renderer', () async {
      final harness = _harness();

      final result = await harness.service.exportToCsv(_range);

      final file = result.getOrElse((_) => throw StateError('expected right'));
      expect(file.fileName, 'mali-transactions_2026-09-01_2026-09-30.csv');
      expect(file.mimeType, 'text/csv');
      expect(harness.fileStore.lastBytes, [5, 6]);
      expect(harness.csvRenderer.lastExport, isNotNull);
      expect(harness.pdfRenderer.lastExport, isNull);
    });

    test('collects the same data as the pdf export', () async {
      final harness = _harness();

      await harness.service.exportToCsv(_range);

      expect(harness.buildExport.lastRange, _range);
      expect(harness.buildExport.lastUserName, 'Tendai');
      expect(harness.buildExport.lastGeneratedAt, DateTime(2026, 10, 1, 8));
    });

    test('fails when nobody is signed in', () async {
      final harness = _harness(signedIn: false);

      final result = await harness.service.exportToCsv(_range);

      expect(result.isLeft(), isTrue);
      expect(harness.fileStore.lastFileName, isNull);
    });

    test('propagates a data collection failure', () async {
      final harness = _harness(
        result: left(const StorageFailure(message: 'db gone')),
      );

      final result = await harness.service.exportToCsv(_range);

      expect(result.isLeft(), isTrue);
      expect(harness.fileStore.lastFileName, isNull);
    });

    test('reports a failure when the file cannot be written', () async {
      final harness = _harness(saveError: StateError('disk full'));

      final result = await harness.service.exportToCsv(_range);

      expect(result.isLeft(), isTrue);
      expect(harness.logger.errors, hasLength(1));
    });
  });

  group('ExportFileName', () {
    test('is deterministic for a range', () {
      expect(
        ExportFileName.forRange(range: _range, extension: 'csv'),
        'mali-transactions_2026-09-01_2026-09-30.csv',
      );
    });
  });
}
