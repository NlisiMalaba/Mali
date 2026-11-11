import 'package:fpdart/fpdart.dart';
import 'package:mali_app/core/error/failure.dart';

enum ReceiptImageSource { camera, gallery }

/// Raw OCR output plus the photo used to produce it.
class ReceiptRecognition {
  const ReceiptRecognition({
    required this.imagePath,
    required this.text,
  });

  final String imagePath;
  final String text;
}

/// Captures a receipt image and returns its text, one visual row per line.
abstract interface class IReceiptTextRecognizer {
  /// Right(null) means the user cancelled picking an image.
  Future<Either<Failure, ReceiptRecognition?>> recognize(
    ReceiptImageSource source,
  );
}
