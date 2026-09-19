import 'dart:io';
import 'dart:typed_data';

import 'package:mali_app/data/export/export_directory_resolver.dart';
import 'package:mali_app/domain/services/export_file_store.dart';
import 'package:mali_app/domain/value_objects/exported_file.dart';

class DownloadsExportFileStore implements IExportFileStore {
  const DownloadsExportFileStore({
    ExportDirectoryResolver directoryResolver = resolveExportDirectory,
  }) : _directoryResolver = directoryResolver;

  final ExportDirectoryResolver _directoryResolver;

  @override
  Future<ExportedFile> save({
    required String fileName,
    required String mimeType,
    required Uint8List bytes,
  }) async {
    final directory = await _directoryResolver();
    final file = File('${directory.path}${Platform.pathSeparator}$fileName');

    await file.writeAsBytes(bytes, flush: true);

    return ExportedFile(
      path: file.path,
      fileName: fileName,
      mimeType: mimeType,
      byteCount: bytes.length,
    );
  }
}
