import 'package:fpdart/fpdart.dart';
import 'package:mali_app/core/constants/pin_lock_constants.dart';
import 'package:mali_app/core/error/failure.dart';
import 'package:mali_app/domain/repositories/pin_lock_repository.dart';

class SetPinParams {
  const SetPinParams({
    required this.pin,
    required this.confirmPin,
  });

  final String pin;
  final String confirmPin;
}

class SetPinUseCase {
  const SetPinUseCase({
    required IPinLockRepository pinLockRepository,
  }) : _pinLockRepository = pinLockRepository;

  final IPinLockRepository _pinLockRepository;

  Future<Either<Failure, void>> call(SetPinParams params) async {
    final pin = params.pin.trim();
    final confirmPin = params.confirmPin.trim();

    if (!_isValidPin(pin)) {
      return left(
        const ValidationFailure(
          message: 'PIN must be exactly 4 digits.',
          field: 'pin',
        ),
      );
    }

    if (pin != confirmPin) {
      return left(
        const ValidationFailure(
          message: 'PINs do not match.',
          field: 'confirmPin',
        ),
      );
    }

    try {
      await _pinLockRepository.savePin(pin);
    } catch (error) {
      return left(
        StorageFailure(
          message: 'Failed to save PIN.',
          cause: error,
        ),
      );
    }

    return right(null);
  }

  bool _isValidPin(String pin) {
    return RegExp(PinLockConstants.pinPattern).hasMatch(pin);
  }
}
