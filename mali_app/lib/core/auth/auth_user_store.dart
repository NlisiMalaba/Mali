import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mali_app/domain/entities/user.dart';

abstract interface class IAuthUserStore {
  Future<User?> readUser();

  Future<void> saveUser(User user);

  Future<void> clearUser();
}

class SecureAuthUserStore implements IAuthUserStore {
  const SecureAuthUserStore({
    FlutterSecureStorage? secureStorage,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const String userKey = 'auth_user';

  final FlutterSecureStorage _secureStorage;

  @override
  Future<User?> readUser() async {
    final raw = await _secureStorage.read(key: userKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) {
        return null;
      }
      return _fromJson(json);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveUser(User user) {
    return _secureStorage.write(
      key: userKey,
      value: jsonEncode(_toJson(user)),
    );
  }

  @override
  Future<void> clearUser() {
    return _secureStorage.delete(key: userKey);
  }

  static Map<String, dynamic> _toJson(User user) => {
        'id': user.id,
        'email': user.email,
        'phone': user.phone,
        'name': user.name,
        'created_at': user.createdAt.toUtc().toIso8601String(),
      };

  static User _fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
