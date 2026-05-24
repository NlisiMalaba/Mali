import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mali_app/domain/repositories/biometric_authenticator.dart';

class LocalAuthBiometricAuthenticator implements IBiometricAuthenticator {
  LocalAuthBiometricAuthenticator({
    LocalAuthentication? localAuth,
  }) : _localAuth = localAuth ?? LocalAuthentication();

  final LocalAuthentication _localAuth;

  @override
  Future<BiometricCapability> getCapability() async {
    try {
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      if (!isDeviceSupported) {
        return const BiometricCapability.unavailable();
      }

      final canCheck = await _localAuth.canCheckBiometrics;
      if (!canCheck) {
        return const BiometricCapability.unavailable();
      }

      final available = await _localAuth.getAvailableBiometrics();
      if (available.isEmpty) {
        return const BiometricCapability.unavailable();
      }

      return BiometricCapability(
        isAvailable: true,
        hasFace: available.contains(BiometricType.face),
        hasFingerprint: available.contains(BiometricType.fingerprint),
        hasIris: available.contains(BiometricType.iris),
      );
    } on PlatformException {
      return const BiometricCapability.unavailable();
    }
  }

  @override
  Future<BiometricAuthResult> authenticate({
    required String localizedReason,
  }) async {
    final capability = await getCapability();
    if (!capability.isAvailable) {
      return const BiometricAuthResult(
        outcome: BiometricAuthOutcome.unavailable,
        message: 'Biometrics are not available on this device.',
      );
    }

    try {
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          sensitiveTransaction: true,
        ),
      );

      if (didAuthenticate) {
        return const BiometricAuthResult(outcome: BiometricAuthOutcome.success);
      }

      return const BiometricAuthResult(
        outcome: BiometricAuthOutcome.failed,
        message: 'Biometric authentication failed.',
      );
    } on PlatformException catch (error) {
      return _mapPlatformException(error);
    }
  }

  BiometricAuthResult _mapPlatformException(PlatformException error) {
    switch (error.code) {
      case 'NotAvailable':
      case 'notAvailable':
      case 'NotEnrolled':
      case 'notEnrolled':
      case 'PasscodeNotSet':
      case 'passcodeNotSet':
        return BiometricAuthResult(
          outcome: BiometricAuthOutcome.unavailable,
          message: error.message ?? 'Biometrics are not available.',
        );
      case 'LockedOut':
      case 'lockedOut':
      case 'PermanentlyLockedOut':
      case 'permanentlyLockedOut':
        return BiometricAuthResult(
          outcome: BiometricAuthOutcome.failed,
          message: 'Too many attempts. Use your PIN instead.',
        );
      case 'UserCanceled':
      case 'userCanceled':
      case 'Canceled':
      case 'canceled':
      case 'SystemCanceled':
      case 'systemCanceled':
        return const BiometricAuthResult(outcome: BiometricAuthOutcome.cancelled);
      default:
        return BiometricAuthResult(
          outcome: BiometricAuthOutcome.failed,
          message: error.message ?? 'Biometric authentication failed.',
        );
    }
  }
}
