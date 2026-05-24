import 'package:mali_app/data/local_auth/local_auth_biometric_authenticator.dart';
import 'package:mali_app/domain/repositories/biometric_authenticator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'biometric_providers.g.dart';

@Riverpod(keepAlive: true)
IBiometricAuthenticator biometricAuthenticator(Ref ref) {
  return LocalAuthBiometricAuthenticator();
}

@riverpod
Future<BiometricCapability> biometricCapability(Ref ref) {
  return ref.watch(biometricAuthenticatorProvider).getCapability();
}
