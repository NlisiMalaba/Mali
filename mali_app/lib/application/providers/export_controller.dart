import 'dart:async';

import 'package:mali_app/application/export/export_request.dart';
import 'package:mali_app/application/providers/export_providers.dart';
import 'package:mali_app/application/providers/logging_providers.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mali_app/core/error/failure.dart';
import 'package:mali_app/domain/value_objects/export_format.dart';
import 'package:mali_app/domain/value_objects/exported_file.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'export_controller.g.dart';

/// Runs an export and then offers the saved file to the share sheet.
///
/// The state holds the most recent successful export so the UI can report
/// where the file landed.
@riverpod
class ExportController extends _$ExportController {
  @override
  FutureOr<ExportedFile?> build() => null;

  Future<void> submit(ExportRequest request) async {
    state = const AsyncLoading();

    final result = await _run(request);

    await result.fold(
      (failure) async {
        state = AsyncError(failure, StackTrace.current);
      },
      (file) async {
        await _share(file);
        state = AsyncData(file);
      },
    );
  }

  Future<Either<Failure, ExportedFile>> _run(ExportRequest request) {
    final service = ref.read(exportServiceProvider);
    return switch (request.format) {
      ExportFormat.pdf =>
        service.exportToPdf(request.range, filters: request.filters),
      ExportFormat.csv =>
        service.exportToCsv(request.range, filters: request.filters),
    };
  }

  /// The file is already saved, so a share sheet failure is logged rather than
  /// reported as an export failure.
  Future<void> _share(ExportedFile file) async {
    try {
      await ref.read(fileShareServiceProvider).shareFile(file);
    } catch (error, stackTrace) {
      ref.read(appLoggerProvider).error(
            'Could not open the share sheet for ${file.fileName}',
            error: error,
            stackTrace: stackTrace,
          );
    }
  }
}

String exportErrorMessage(Object error) {
  if (error is Failure) {
    return error.message;
  }
  return 'Failed to export transactions.';
}
