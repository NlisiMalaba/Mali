import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Hashes PINs for secure local storage (never persist the raw PIN).
abstract final class PinHasher {
  static const int _saltByteLength = 16;

  static String generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(_saltByteLength, (_) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  static String hashPin({
    required String pin,
    required String salt,
  }) {
    final bytes = utf8.encode('$salt:$pin');
    return sha256.convert(bytes).toString();
  }

  static bool verify({
    required String pin,
    required String salt,
    required String expectedHash,
  }) {
    final actual = hashPin(pin: pin, salt: salt);
    return _constantTimeEquals(actual, expectedHash);
  }

  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) {
      return false;
    }
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}
