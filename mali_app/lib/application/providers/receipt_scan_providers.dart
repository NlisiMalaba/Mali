import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mali_app/data/ocr/ml_kit_receipt_text_recognizer.dart';
import 'package:mali_app/domain/repositories/receipt_text_recognizer.dart';
import 'package:mali_app/domain/services/receipt_parser.dart';
import 'package:mali_app/domain/usecases/scan_receipt_usecase.dart';

final receiptTextRecognizerProvider = Provider<IReceiptTextRecognizer>(
  (ref) => MlKitReceiptTextRecognizer(),
);

final scanReceiptUseCaseProvider = Provider<ScanReceiptUseCase>(
  (ref) => ScanReceiptUseCase(
    recognizer: ref.watch(receiptTextRecognizerProvider),
    parser: const ReceiptParser(),
  ),
);
