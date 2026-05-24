import 'package:fpdart/fpdart.dart';
import 'package:mali_app/core/constants/pin_lock_constants.dart';
import 'package:mali_app/core/error/failure.dart';
import 'package:mali_app/domain/repositories/pin_lock_repository.dart';

class VerifyPinUseCase {
  const VerifyPinUseCase({
    required IPinLockRepository pinLockRepository,
  }) : _pinLockRepository = pinLockRepository;

  final IPinLockRepository _pinLockRepository;

  Future<Either<Failure, void>> call(String pin) async {
    final normalized = pin.trim();
    if (!RegExp(PinLockConstants.pinPattern).hasMatch(normalized)) {
      return left(
        const ValidationFailure(
          message: 'PIN must be exactly 4 digits.',
          field: 'pin',
        ),
      );
    }

    try {
      final isValid = await _pinLockRepository.verifyPin(normalized);
      if (!isValid) {
        return left(
          const AuthFailure(message: 'Incorrect PIN.'),
        );
      }
    } catch (error) {
      return left(
        StorageFailure(
          message: 'Could not verify PIN.',
          cause: error,
        ),
      );
    }

    return right(null);
  }
}
