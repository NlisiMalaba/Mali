import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Resolves where exports should be written.
typedef ExportDirectoryResolver = Future<Directory> Function();

/// Default resolver.
///
/// `path_provider` only implements `getDownloadsDirectory` on desktop, exposes
/// an app-scoped Downloads folder on Android, and offers nothing equivalent on
/// iOS. This walks those options in order and falls back to the app documents
/// directory, which stays reachable through the share sheet.
Future<Directory> resolveExportDirectory() async {
  final candidate = await _platformDownloadsDirectory();
  final directory = candidate ?? await getApplicationDocumentsDirectory();

  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }
  return directory;
}

Future<Directory?> _platformDownloadsDirectory() async {
  try {
    final downloads = await getDownloadsDirectory();
    if (downloads != null) {
      return downloads;
    }
  } on UnsupportedError {
    // Expected on mobile platforms; fall through to the Android option below.
  }

  if (!Platform.isAndroid) {
    return null;
  }

  try {
    final directories = await getExternalStorageDirectories(
      type: StorageDirectory.downloads,
    );
    if (directories != null && directories.isNotEmpty) {
      return directories.first;
    }
  } on UnsupportedError {
    return null;
  }

  return null;
}
