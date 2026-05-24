import 'package:fpdart/fpdart.dart';
import 'package:mali_app/core/error/failure.dart';
import 'package:mali_app/domain/repositories/pin_lock_repository.dart';
import 'package:mali_app/domain/usecases/verify_pin_usecase.dart';

class DisablePinLockUseCase {
  const DisablePinLockUseCase({
    required IPinLockRepository pinLockRepository,
    required VerifyPinUseCase verifyPinUseCase,
  })  : _pinLockRepository = pinLockRepository,
        _verifyPinUseCase = verifyPinUseCase;

  final IPinLockRepository _pinLockRepository;
  final VerifyPinUseCase _verifyPinUseCase;

  Future<Either<Failure, void>> call(String pin) async {
    final verifyResult = await _verifyPinUseCase(pin);
    if (verifyResult.isLeft()) {
      return left(verifyResult.getLeft().toNullable()!);
    }

    try {
      await _pinLockRepository.disable();
    } catch (error) {
      return left(
        StorageFailure(
          message: 'Failed to disable PIN lock.',
          cause: error,
        ),
      );
    }

    return right(null);
  }
}
