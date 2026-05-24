import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class IPinLockStore {
  Future<bool> isEnabled();

  Future<bool> isBiometricEnabled();

  Future<String?> readPinHash();

  Future<String?> readPinSalt();

  Future<void> savePin({
    required String hash,
    required String salt,
  });

  Future<void> setEnabled(bool enabled);

  Future<void> setBiometricEnabled(bool enabled);

  Future<void> clearPin();
}

class SecurePinLockStore implements IPinLockStore {
  const SecurePinLockStore({
    FlutterSecureStorage? secureStorage,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const String enabledKey = 'pin_lock_enabled';
  static const String biometricEnabledKey = 'pin_lock_biometric_enabled';
  static const String hashKey = 'pin_lock_hash';
  static const String saltKey = 'pin_lock_salt';

  final FlutterSecureStorage _secureStorage;

  @override
  Future<bool> isEnabled() async {
    final value = await _secureStorage.read(key: enabledKey);
    return value == 'true';
  }

  @override
  Future<bool> isBiometricEnabled() async {
    final value = await _secureStorage.read(key: biometricEnabledKey);
    return value == 'true';
  }

  @override
  Future<String?> readPinHash() => _read(hashKey);

  @override
  Future<String?> readPinSalt() => _read(saltKey);

  @override
  Future<void> savePin({
    required String hash,
    required String salt,
  }) async {
    await Future.wait<void>([
      _secureStorage.write(key: hashKey, value: hash),
      _secureStorage.write(key: saltKey, value: salt),
      _secureStorage.write(key: enabledKey, value: 'true'),
    ]);
  }

  @override
  Future<void> setEnabled(bool enabled) {
    return _secureStorage.write(
      key: enabledKey,
      value: enabled.toString(),
    );
  }

  @override
  Future<void> setBiometricEnabled(bool enabled) {
    if (enabled) {
      return _secureStorage.write(key: biometricEnabledKey, value: 'true');
    }
    return _secureStorage.delete(key: biometricEnabledKey);
  }

  @override
  Future<void> clearPin() async {
    await Future.wait<void>([
      _secureStorage.delete(key: hashKey),
      _secureStorage.delete(key: saltKey),
      _secureStorage.delete(key: enabledKey),
      _secureStorage.delete(key: biometricEnabledKey),
    ]);
  }

  Future<String?> _read(String key) async {
    final value = await _secureStorage.read(key: key);
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }
}
