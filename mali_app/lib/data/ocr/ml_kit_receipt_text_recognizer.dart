import 'dart:ui';

import 'package:fpdart/fpdart.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mali_app/core/error/failure.dart';
import 'package:mali_app/domain/repositories/receipt_text_recognizer.dart';

/// On-device OCR with Google ML Kit; images never leave the phone.
class MlKitReceiptTextRecognizer implements IReceiptTextRecognizer {
  MlKitReceiptTextRecognizer({ImagePicker? picker})
      : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  static const double _maxImageWidth = 2000;
  static const int _imageQuality = 85;

  /// Two text lines belong to the same row when their vertical centres are
  /// closer than this fraction of the line height.
  static const double _rowTolerance = 0.6;

  @override
  Future<Either<Failure, String?>> recognize(ReceiptImageSource source) async {
    final XFile? image;
    try {
      image = await _picker.pickImage(
        source: source == ReceiptImageSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        maxWidth: _maxImageWidth,
        imageQuality: _imageQuality,
      );
    } catch (error) {
      return left(
        StorageFailure(
          message: 'Couldn\'t open the camera or gallery. '
              'Check Mali\'s permissions.',
          cause: error,
        ),
      );
    }
    if (image == null) {
      return right(null);
    }

    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(
        InputImage.fromFilePath(image.path),
      );
      return right(_rowsFrom(result));
    } catch (error) {
      return left(
        StorageFailure(message: 'Couldn\'t read the photo.', cause: error),
      );
    } finally {
      await recognizer.close();
    }
  }

  /// ML Kit groups text into column blocks, which separates "TOTAL" from its
  /// amount. Rebuild visual rows so the parser sees them on one line.
  String _rowsFrom(RecognizedText recognized) {
    final lines = recognized.blocks.expand((block) => block.lines).toList()
      ..sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));

    final rows = <List<TextLine>>[];
    for (final line in lines) {
      final box = line.boundingBox;
      final row = rows.isEmpty ? null : rows.last;
      if (row != null && _sameRow(row.first.boundingBox, box)) {
        row.add(line);
      } else {
        rows.add([line]);
      }
    }

    return rows.map((row) {
      row.sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));
      return row.map((line) => line.text).join('  ');
    }).join('\n');
  }

  bool _sameRow(Rect a, Rect b) {
    final tolerance = a.height * _rowTolerance;
    return (a.center.dy - b.center.dy).abs() < tolerance;
  }
}
