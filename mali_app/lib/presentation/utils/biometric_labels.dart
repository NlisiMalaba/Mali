import 'package:mali_app/domain/repositories/biometric_authenticator.dart';

abstract final class BiometricLabels {
  static String unlockAction(BiometricCapability capability) {
    if (capability.hasFace && !capability.hasFingerprint) {
      return 'Use Face ID';
    }
    if (capability.hasFingerprint && !capability.hasFace) {
      return 'Use fingerprint';
    }
    if (capability.hasFace && capability.hasFingerprint) {
      return 'Use biometrics';
    }
    if (capability.hasIris) {
      return 'Use iris scan';
    }
    return 'Use biometrics';
  }

  static String settingsTitle(BiometricCapability capability) {
    if (capability.hasFace && !capability.hasFingerprint) {
      return 'Unlock with Face ID';
    }
    if (capability.hasFingerprint && !capability.hasFace) {
      return 'Unlock with fingerprint';
    }
    return 'Unlock with biometrics';
  }

  static String settingsSubtitle(BiometricCapability capability) {
    return 'Faster than typing your PIN';
  }
}
