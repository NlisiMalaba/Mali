import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mali_app/application/providers/repository_providers.dart';
import 'package:mali_app/domain/value_objects/currency_code.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'transfer_exchange_rate_provider.g.dart';

typedef TransferRateKey = ({String fromCurrency, String toCurrency});

@riverpod
Future<String?> suggestedTransferExchangeRate(
  Ref ref,
  TransferRateKey key,
) async {
  if (key.fromCurrency == key.toCurrency) {
    return null;
  }

  final rate = await ref.read(exchangeRateRepositoryProvider).getRate(
        baseCurrencyCode: CurrencyCode(key.fromCurrency),
        quoteCurrencyCode: CurrencyCode(key.toCurrency),
      );

  return rate?.rate;
}
