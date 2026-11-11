import 'package:flutter_test/flutter_test.dart';
import 'package:mali_app/domain/value_objects/currency_code.dart';
import 'package:mali_app/presentation/utils/currency_display.dart';

void main() {
  group('CurrencyDisplay.flagEmoji', () {
    test('maps supported currencies to country flags', () {
      expect(CurrencyDisplay.flagEmoji(CurrencyCode.usd), '🇺🇸');
      expect(CurrencyDisplay.flagEmoji(CurrencyCode.zwg), '🇿🇼');
      expect(CurrencyDisplay.flagEmoji(CurrencyCode.zar), '🇿🇦');
      expect(CurrencyDisplay.flagEmoji(CurrencyCode.bwp), '🇧🇼');
    });

    test('falls back for unknown codes', () {
      expect(CurrencyDisplay.flagEmojiForCode('XYZ'), '🏳️');
    });
  });

  group('CurrencyDisplay.codeWithFlag', () {
    test('prefixes ISO code with flag', () {
      expect(CurrencyDisplay.codeWithFlag(CurrencyCode.usd), '🇺🇸 USD');
      expect(
        CurrencyDisplay.codeWithFlagForCode('zar'),
        '🇿🇦 ZAR',
      );
    });
  });
}
