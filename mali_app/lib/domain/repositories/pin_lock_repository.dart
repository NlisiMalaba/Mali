abstract interface class IPinLockRepository {
  Future<bool> isEnabled();

  Future<bool> isBiometricEnabled();

  Future<void> savePin(String pin);

  Future<bool> verifyPin(String pin);

  Future<void> setBiometricEnabled(bool enabled);

  Future<void> disable();
}
