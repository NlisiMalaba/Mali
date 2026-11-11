import 'package:mali_app/domain/value_objects/currency_code.dart';

class CurrencyDisplay {
  const CurrencyDisplay._();

  static String flagEmoji(CurrencyCode currency) =>
      flagEmojiForCode(currency.value);

  /// Flag for a raw ISO code such as wallet `currencyCode` strings.
  static String flagEmojiForCode(String currencyCode) {
    switch (currencyCode.trim().toUpperCase()) {
      case 'USD':
        return '🇺🇸';
      case 'ZWG':
        return '🇿🇼';
      case 'ZAR':
        return '🇿🇦';
      case 'BWP':
        return '🇧🇼';
      default:
        return '🏳️';
    }
  }

  /// Compact "🇺🇸 USD" label used in pickers, chips, and list rows.
  static String codeWithFlag(CurrencyCode currency) =>
      '${flagEmoji(currency)} ${currency.value}';

  static String codeWithFlagForCode(String currencyCode) {
    final normalized = currencyCode.trim().toUpperCase();
    return '${flagEmojiForCode(normalized)} $normalized';
  }

  static String label(CurrencyCode currency) {
    switch (currency.value) {
      case 'USD':
        return 'US Dollar';
      case 'ZWG':
        return 'Zimbabwe Gold';
      case 'ZAR':
        return 'South African Rand';
      case 'BWP':
        return 'Botswana Pula';
      default:
        return currency.value;
    }
  }

  /// Compact currency prefix shown beside the amount entry, e.g. `$`, `R`, `ZiG`.
  static String symbol(CurrencyCode currency) {
    switch (currency.value) {
      case 'USD':
        return r'$';
      case 'ZAR':
        return 'R';
      case 'ZWG':
        return 'ZiG';
      case 'BWP':
        return 'P';
      default:
        return currency.value;
    }
  }
}
