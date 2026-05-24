import 'package:fpdart/fpdart.dart';
import 'package:mali_app/core/error/failure.dart';
import 'package:mali_app/domain/repositories/biometric_authenticator.dart';
import 'package:mali_app/domain/repositories/pin_lock_repository.dart';

class SetBiometricUnlockParams {
  const SetBiometricUnlockParams({required this.enabled});

  final bool enabled;
}

class SetBiometricUnlockUseCase {
  const SetBiometricUnlockUseCase({
    required IPinLockRepository pinLockRepository,
    required IBiometricAuthenticator biometricAuthenticator,
  })  : _pinLockRepository = pinLockRepository,
        _biometricAuthenticator = biometricAuthenticator;

  final IPinLockRepository _pinLockRepository;
  final IBiometricAuthenticator _biometricAuthenticator;

  static const String _enableReason =
      'Confirm your biometrics to enable quick unlock';

  Future<Either<Failure, void>> call(SetBiometricUnlockParams params) async {
    final pinEnabled = await _pinLockRepository.isEnabled();
    if (!pinEnabled) {
      return left(
        const ValidationFailure(
          message: 'Enable PIN lock before using biometrics.',
        ),
      );
    }

    if (!params.enabled) {
      try {
        await _pinLockRepository.setBiometricEnabled(false);
      } catch (error) {
        return left(
          StorageFailure(
            message: 'Failed to disable biometric unlock.',
            cause: error,
          ),
        );
      }
      return right(null);
    }

    final capability = await _biometricAuthenticator.getCapability();
    if (!capability.isAvailable) {
      return left(
        const ValidationFailure(
          message: 'Biometrics are not available on this device.',
        ),
      );
    }

    final auth = await _biometricAuthenticator.authenticate(
      localizedReason: _enableReason,
    );
    switch (auth.outcome) {
      case BiometricAuthOutcome.success:
        break;
      case BiometricAuthOutcome.cancelled:
        return left(
          const ValidationFailure(
            message: 'Biometric setup cancelled.',
          ),
        );
      case BiometricAuthOutcome.failed:
      case BiometricAuthOutcome.unavailable:
        return left(
          ValidationFailure(
            message: auth.message ?? 'Biometric confirmation failed.',
          ),
        );
    }

    try {
      await _pinLockRepository.setBiometricEnabled(true);
    } catch (error) {
      return left(
        StorageFailure(
          message: 'Failed to enable biometric unlock.',
          cause: error,
        ),
      );
    }

    return right(null);
  }
}
