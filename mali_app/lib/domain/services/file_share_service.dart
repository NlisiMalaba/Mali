import 'package:mali_app/domain/value_objects/exported_file.dart';

/// Hands a saved file to the platform share sheet.
abstract interface class IFileShareService {
  Future<void> shareFile(ExportedFile file);
}
