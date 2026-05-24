import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class IAuthTokenStore {
  Future<String?> readAccessToken();

  Future<String?> readRefreshToken();

  Future<String> readOrCreateDeviceId();

  Future<void> saveSession({
    required String accessToken,
    String? refreshToken,
  });

  Future<void> clear();
}

class SecureAuthTokenStore implements IAuthTokenStore {
  const SecureAuthTokenStore({
    FlutterSecureStorage? secureStorage,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const String accessTokenKey = 'auth_access_token';
  static const String refreshTokenKey = 'auth_refresh_token';
  static const String deviceIdKey = 'auth_device_id';

  final FlutterSecureStorage _secureStorage;

  @override
  Future<String?> readAccessToken() => _read(accessTokenKey);

  @override
  Future<String?> readRefreshToken() => _read(refreshTokenKey);

  @override
  Future<String> readOrCreateDeviceId() async {
    final existing = await _read(deviceIdKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final deviceId = _generateDeviceId();
    await _secureStorage.write(key: deviceIdKey, value: deviceId);
    return deviceId;
  }

  @override
  Future<void> saveSession({
    required String accessToken,
    String? refreshToken,
  }) async {
    await _secureStorage.write(key: accessTokenKey, value: accessToken);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _secureStorage.write(key: refreshTokenKey, value: refreshToken);
    }
  }

  @override
  Future<void> clear() async {
    await Future.wait<void>([
      _secureStorage.delete(key: accessTokenKey),
      _secureStorage.delete(key: refreshTokenKey),
    ]);
  }

  Future<String?> _read(String key) async {
    final value = await _secureStorage.read(key: key);
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  static String _generateDeviceId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    String hex(int byte) => byte.toRadixString(16).padLeft(2, '0');

    return '${hex(bytes[0])}${hex(bytes[1])}${hex(bytes[2])}${hex(bytes[3])}-'
        '${hex(bytes[4])}${hex(bytes[5])}-'
        '${hex(bytes[6])}${hex(bytes[7])}-'
        '${hex(bytes[8])}${hex(bytes[9])}-'
        '${hex(bytes[10])}${hex(bytes[11])}${hex(bytes[12])}${hex(bytes[13])}'
        '${hex(bytes[14])}${hex(bytes[15])}';
  }
}
