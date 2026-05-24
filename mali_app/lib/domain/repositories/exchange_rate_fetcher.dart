import 'package:fpdart/fpdart.dart';
import 'package:mali_app/core/error/failure.dart';
import 'package:mali_app/domain/value_objects/currency_code.dart';

/// Fetched rate for a single base → quote pair (1 base = [rate] quote).
class FetchedExchangeRate {
  const FetchedExchangeRate({
    required this.base,
    required this.quote,
    required this.rate,
  });

  final CurrencyCode base;
  final CurrencyCode quote;
  final String rate;
}

/// External source for market exchange rates (Frankfurter API).
abstract interface class IExchangeRateFetcher {
  Future<Either<Failure, List<FetchedExchangeRate>>> fetchLatestRates();
}
