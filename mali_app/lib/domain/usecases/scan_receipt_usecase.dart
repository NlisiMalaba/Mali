import 'package:fpdart/fpdart.dart';
import 'package:mali_app/core/error/failure.dart';
import 'package:mali_app/domain/repositories/receipt_text_recognizer.dart';
import 'package:mali_app/domain/services/receipt_parser.dart';
import 'package:mali_app/domain/value_objects/receipt_scan.dart';

/// Captures a receipt and extracts what it can for a new expense.
///
/// Right(null) means the user cancelled; nothing should change on screen.
class ScanReceiptUseCase {
  const ScanReceiptUseCase({
    required IReceiptTextRecognizer recognizer,
    required ReceiptParser parser,
  })  : _recognizer = recognizer,
        _parser = parser;

  final IReceiptTextRecognizer _recognizer;
  final ReceiptParser _parser;

  Future<Either<Failure, ReceiptScan?>> call(ReceiptImageSource source) async {
    final recognized = await _recognizer.recognize(source);
    return recognized.fold(
      (failure) => left<Failure, ReceiptScan?>(failure),
      (text) {
        if (text == null) {
          return right<Failure, ReceiptScan?>(null);
        }
        final scan = _parser.parse(text);
        if (scan.isEmpty) {
          return left<Failure, ReceiptScan?>(
            const ValidationFailure(
              message: 'Couldn\'t read this receipt. Try a flatter, '
                  'well-lit photo.',
            ),
          );
        }
        return right<Failure, ReceiptScan?>(scan);
      },
    );
  }
}
