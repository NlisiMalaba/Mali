import 'package:mali_app/domain/repositories/biometric_authenticator.dart';

class AuthenticateWithBiometricUseCase {
  const AuthenticateWithBiometricUseCase({
    required IBiometricAuthenticator biometricAuthenticator,
  }) : _biometricAuthenticator = biometricAuthenticator;

  final IBiometricAuthenticator _biometricAuthenticator;

  static const String _unlockReason = 'Unlock Mali';

  Future<BiometricAuthResult> call() {
    return _biometricAuthenticator.authenticate(
      localizedReason: _unlockReason,
    );
  }
}
