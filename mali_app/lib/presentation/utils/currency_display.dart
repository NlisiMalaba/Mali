import 'package:mali_app/domain/value_objects/currency_code.dart';

class CurrencyDisplay {
  const CurrencyDisplay._();

  static String flagEmoji(CurrencyCode currency) {
    switch (currency.value) {
      case 'USD':
        return '🇺🇸';
      case 'ZWG':
        return '🇿🇼';
      case 'ZAR':
        return '🇿🇦';
      case 'BWP':
        return '🇧🇼';
      default:
        return currency.value;
    }
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
}
