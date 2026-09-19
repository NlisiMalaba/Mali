import 'dart:typed_data';

import 'package:mali_app/domain/usecases/build_transaction_export_usecase.dart';

/// Turns collected export data into the bytes of a concrete document format.
///
/// One implementation per format keeps the rendering logic out of
/// `ExportService`, which only orchestrates.
abstract interface class IExportRenderer {
  /// Extension without the leading dot, for example `pdf`.
  String get fileExtension;

  String get mimeType;

  Future<Uint8List> render(TransactionExport export);
}
