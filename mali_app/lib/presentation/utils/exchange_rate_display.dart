import 'package:mali_app/domain/entities/exchange_rate.dart';
import 'package:mali_app/domain/exchange_rates/exchange_rate_catalog.dart';
import 'package:mali_app/domain/value_objects/currency_code.dart';
import 'package:mali_app/presentation/utils/exchange_rate_labels.dart';

abstract final class ExchangeRateDisplay {
  static String pairLabel(CurrencyCode base, CurrencyCode quote) {
    return '1 ${base.value} = ${quote.value}';
  }

  static String rateValue(ExchangeRate? rate) {
    if (rate == null) {
      return 'Not set';
    }
    return rate.rate;
  }

  static String sourceLabel(ExchangeRate? rate) {
    if (rate == null) {
      return 'Tap to set';
    }
    return rate.isManual ? 'Manual' : 'Auto-fetched';
  }

  static String? updatedSubtitle(ExchangeRate? rate, DateTime now) {
    if (rate == null) {
      return null;
    }
    return ExchangeRateLabels.lastUpdated(rate.updatedAt.toLocal(), now);
  }

  static ExchangeRate? rateForPair(
    List<ExchangeRate> rates,
    ExchangeRatePairRef pair,
  ) {
    for (final rate in rates) {
      if (rate.baseCurrencyCode == pair.base.value &&
          rate.quoteCurrencyCode == pair.quote.value) {
        return rate;
      }
    }
    return null;
  }
}
