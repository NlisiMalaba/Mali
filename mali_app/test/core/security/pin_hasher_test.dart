import 'package:flutter_test/flutter_test.dart';
import 'package:mali_app/domain/services/pin_hasher.dart';

void main() {
  group('PinHasher', () {
    test('verify returns true for matching pin and hash', () {
      const pin = '1234';
      final salt = PinHasher.generateSalt();
      final hash = PinHasher.hashPin(pin: pin, salt: salt);

      expect(
        PinHasher.verify(pin: pin, salt: salt, expectedHash: hash),
        isTrue,
      );
    });

    test('verify returns false for wrong pin', () {
      final salt = PinHasher.generateSalt();
      final hash = PinHasher.hashPin(pin: '1234', salt: salt);

      expect(
        PinHasher.verify(pin: '0000', salt: salt, expectedHash: hash),
        isFalse,
      );
    });
  });
}
