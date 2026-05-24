import 'package:mali_app/core/security/pin_lock_store.dart';
import 'package:mali_app/domain/repositories/pin_lock_repository.dart';
import 'package:mali_app/domain/services/pin_hasher.dart';

class SecurePinLockRepository implements IPinLockRepository {
  const SecurePinLockRepository({
    required IPinLockStore pinLockStore,
  }) : _pinLockStore = pinLockStore;

  final IPinLockStore _pinLockStore;

  @override
  Future<bool> isEnabled() => _pinLockStore.isEnabled();

  @override
  Future<bool> isBiometricEnabled() => _pinLockStore.isBiometricEnabled();

  @override
  Future<void> savePin(String pin) async {
    final salt = PinHasher.generateSalt();
    final hash = PinHasher.hashPin(pin: pin, salt: salt);
    await _pinLockStore.savePin(hash: hash, salt: salt);
  }

  @override
  Future<bool> verifyPin(String pin) async {
    final hash = await _pinLockStore.readPinHash();
    final salt = await _pinLockStore.readPinSalt();
    if (hash == null || salt == null) {
      return false;
    }
    return PinHasher.verify(pin: pin, salt: salt, expectedHash: hash);
  }

  @override
  Future<void> setBiometricEnabled(bool enabled) {
    return _pinLockStore.setBiometricEnabled(enabled);
  }

  @override
  Future<void> disable() => _pinLockStore.clearPin();
}
