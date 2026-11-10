import 'package:fpdart/fpdart.dart';
import 'package:mali_app/core/error/failure.dart';

enum ReceiptImageSource { camera, gallery }

/// Captures a receipt image and returns its text, one visual row per line.
abstract interface class IReceiptTextRecognizer {
  /// Right(null) means the user cancelled picking an image.
  Future<Either<Failure, String?>> recognize(ReceiptImageSource source);
}
