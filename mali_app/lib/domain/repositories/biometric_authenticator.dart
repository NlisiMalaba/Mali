/// Device biometric capabilities for Mali unlock.
class BiometricCapability {
  const BiometricCapability({
    required this.isAvailable,
    required this.hasFace,
    required this.hasFingerprint,
    required this.hasIris,
  });

  const BiometricCapability.unavailable()
      : isAvailable = false,
        hasFace = false,
        hasFingerprint = false,
        hasIris = false;

  final bool isAvailable;
  final bool hasFace;
  final bool hasFingerprint;
  final bool hasIris;
}

enum BiometricAuthOutcome {
  success,
  cancelled,
  failed,
  unavailable,
}

class BiometricAuthResult {
  const BiometricAuthResult({
    required this.outcome,
    this.message,
  });

  final BiometricAuthOutcome outcome;
  final String? message;

  bool get isSuccess => outcome == BiometricAuthOutcome.success;
}

/// Platform biometric authentication (fingerprint, Face ID, etc.).
abstract interface class IBiometricAuthenticator {
  Future<BiometricCapability> getCapability();

  Future<BiometricAuthResult> authenticate({
    required String localizedReason,
  });
}
