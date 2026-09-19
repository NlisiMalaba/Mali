import 'package:mali_app/domain/services/file_share_service.dart';
import 'package:mali_app/domain/value_objects/exported_file.dart';
import 'package:share_plus/share_plus.dart';

class SharePlusFileShareService implements IFileShareService {
  const SharePlusFileShareService();

  static const String shareSubject = 'Mali transactions';

  @override
  Future<void> shareFile(ExportedFile file) async {
    await SharePlus.instance.share(
      ShareParams(
        subject: shareSubject,
        files: [
          XFile(
            file.path,
            mimeType: file.mimeType,
            name: file.fileName,
          ),
        ],
        // Some platforms ignore XFile.name, so the name is set explicitly.
        fileNameOverrides: [file.fileName],
      ),
    );
  }
}
