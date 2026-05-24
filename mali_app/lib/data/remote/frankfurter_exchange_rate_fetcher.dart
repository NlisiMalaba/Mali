import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mali_app/core/error/failure.dart';
import 'package:mali_app/domain/repositories/exchange_rate_fetcher.dart';
import 'package:mali_app/domain/value_objects/currency_code.dart';

/// Fetches USD-based rates from Frankfurter (same source as the backend worker).
class FrankfurterExchangeRateFetcher implements IExchangeRateFetcher {
  FrankfurterExchangeRateFetcher({
    Dio? dio,
    this.baseUrl = 'https://api.frankfurter.app',
  }) : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 15),
              ),
            );

  static const String _latestPath = '/latest';

  final Dio _dio;
  final String baseUrl;

  static const CurrencyCode _baseCurrency = CurrencyCode.usd;
  static const List<CurrencyCode> _quoteCurrencies = [
    CurrencyCode.zar,
    CurrencyCode.bwp,
  ];

  @override
  Future<Either<Failure, List<FetchedExchangeRate>>> fetchLatestRates() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$baseUrl$_latestPath',
        queryParameters: {
          'from': _baseCurrency.value,
          'to': _quoteCurrencies.map((c) => c.value).join(','),
        },
      );

      final data = response.data;
      if (data == null) {
        return left(
          const NetworkFailure(message: 'Exchange rate provider returned no data.'),
        );
      }

      final ratesObject = data['rates'];
      if (ratesObject is! Map<String, dynamic> || ratesObject.isEmpty) {
        return left(
          const NetworkFailure(
            message: 'Exchange rate provider response did not contain rates.',
          ),
        );
      }

      final fetched = <FetchedExchangeRate>[];
      for (final quote in _quoteCurrencies) {
        final raw = ratesObject[quote.value];
        if (raw == null) {
          return left(
            NetworkFailure(
              message: 'Missing ${quote.value} rate in provider response.',
            ),
          );
        }
        final rate = raw.toString().trim();
        if (rate.isEmpty) {
          return left(
            NetworkFailure(
              message: 'Missing ${quote.value} rate in provider response.',
            ),
          );
        }
        fetched.add(
          FetchedExchangeRate(
            base: _baseCurrency,
            quote: quote,
            rate: rate,
          ),
        );
      }

      return right(fetched);
    } on DioException catch (error) {
      return left(
        NetworkFailure(
          message: 'Could not fetch exchange rates. Check your connection.',
          cause: error,
          statusCode: error.response?.statusCode,
        ),
      );
    } catch (error) {
      return left(
        NetworkFailure(
          message: 'Could not fetch exchange rates.',
          cause: error,
        ),
      );
    }
  }
}
