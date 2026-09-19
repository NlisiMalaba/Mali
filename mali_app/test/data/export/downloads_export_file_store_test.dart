import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mali_app/data/export/downloads_export_file_store.dart';

void main() {
  late Directory tempDirectory;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('mali-export-test');
  });

  tearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  group('DownloadsExportFileStore', () {
    test('writes bytes to the resolved directory', () async {
      final store = DownloadsExportFileStore(
        directoryResolver: () async => tempDirectory,
      );
      final bytes = Uint8List.fromList([10, 20, 30]);

      final saved = await store.save(
        fileName: 'report.pdf',
        mimeType: 'application/pdf',
        bytes: bytes,
      );

      expect(saved.fileName, 'report.pdf');
      expect(saved.mimeType, 'application/pdf');
      expect(saved.byteCount, 3);
      expect(await File(saved.path).readAsBytes(), bytes);
    });

    test('replaces a previous export with the same name', () async {
      final store = DownloadsExportFileStore(
        directoryResolver: () async => tempDirectory,
      );

      await store.save(
        fileName: 'report.pdf',
        mimeType: 'application/pdf',
        bytes: Uint8List.fromList([1, 2, 3, 4, 5]),
      );
      final saved = await store.save(
        fileName: 'report.pdf',
        mimeType: 'application/pdf',
        bytes: Uint8List.fromList([9]),
      );

      expect(saved.byteCount, 1);
      expect(await File(saved.path).readAsBytes(), [9]);
    });
  });
}
