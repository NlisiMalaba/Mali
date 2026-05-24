import 'package:mali_app/domain/value_objects/currency_code.dart';

/// Describes a currency pair users can view and edit in settings.
class ExchangeRatePairRef {
  const ExchangeRatePairRef({
    required this.base,
    required this.quote,
    required this.autoFetchedFromApi,
  });

  final CurrencyCode base;
  final CurrencyCode quote;

  /// When true, the refresh action may update this pair from Frankfurter.
  final bool autoFetchedFromApi;

  String get key => '${base.value}|${quote.value}';
}

/// Canonical list of exchange-rate pairs supported by Mali.
abstract final class ExchangeRateCatalog {
  static final List<ExchangeRatePairRef> allPairs = _buildAllPairs();

  static List<ExchangeRatePairRef> _buildAllPairs() {
    final pairs = <ExchangeRatePairRef>[];
    for (final base in CurrencyCode.values) {
      for (final quote in CurrencyCode.values) {
        if (base == quote) {
          continue;
        }
        pairs.add(
          ExchangeRatePairRef(
            base: base,
            quote: quote,
            autoFetchedFromApi: _isAutoFetchedPair(base, quote),
          ),
        );
      }
    }
    pairs.sort(
      (a, b) => a.key.compareTo(b.key),
    );
    return pairs;
  }

  static bool _isAutoFetchedPair(CurrencyCode base, CurrencyCode quote) {
    return base == CurrencyCode.usd &&
        (quote == CurrencyCode.zar || quote == CurrencyCode.bwp);
  }
}
