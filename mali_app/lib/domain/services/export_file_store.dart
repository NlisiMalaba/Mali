import 'dart:typed_data';

import 'package:mali_app/domain/value_objects/exported_file.dart';

/// Writes export documents to device storage.
abstract interface class IExportFileStore {
  Future<ExportedFile> save({
    required String fileName,
    required String mimeType,
    required Uint8List bytes,
  });
}
