import 'package:intl/intl.dart';
import 'package:mali_app/domain/entities/exchange_rate.dart';
import 'package:mali_app/presentation/utils/money_display.dart';

/// Presentation copy for Exchange Rates list rows.
class ExchangeRateRowCopy {
  const ExchangeRateRowCopy._();

  static String chipLabel(ExchangeRate? rate) {
    if (rate == null) {
      return 'Tap to set';
    }
    return rate.isManual ? 'Manual' : 'Auto';
  }

  static String subtitle(ExchangeRate? rate, DateTime now) {
    if (rate == null) {
      return 'Tap to set your rate';
    }
    final local = rate.updatedAt.toLocal();
    if (rate.isManual) {
      return 'Set by you · ${DateFormat('d MMM').format(local)}';
    }
    final sameDay = local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
    if (sameDay) {
      return 'Updated today, ${DateFormat('HH:mm').format(local)}';
    }
    return 'Updated ${DateFormat('d MMM').format(local)}';
  }

  static String rateAmount(ExchangeRate? rate, String quoteCurrencyCode) {
    if (rate == null) {
      return 'Not set';
    }
    return MoneyDisplay.compact(
      amount: rate.rate,
      currencyCode: quoteCurrencyCode,
    );
  }
}
