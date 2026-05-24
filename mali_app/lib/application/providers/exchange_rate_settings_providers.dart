import 'package:mali_app/application/providers/connectivity_provider.dart';
import 'package:mali_app/application/providers/home_providers.dart';
import 'package:mali_app/application/providers/repository_providers.dart';
import 'package:mali_app/application/providers/use_case_providers.dart';
import 'package:mali_app/domain/entities/exchange_rate.dart';
import 'package:mali_app/domain/exchange_rates/exchange_rate_catalog.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'exchange_rate_settings_providers.g.dart';

class ExchangeRateSettingsItem {
  const ExchangeRateSettingsItem({
    required this.pair,
    required this.rate,
  });

  final ExchangeRatePairRef pair;
  final ExchangeRate? rate;
}

@riverpod
Stream<List<ExchangeRateSettingsItem>> exchangeRateSettingsItems(Ref ref) {
  return ref.watch(exchangeRateRepositoryProvider).watchAllRates().map(
        (rates) {
          return ExchangeRateCatalog.allPairs
              .map(
                (pair) => ExchangeRateSettingsItem(
                  pair: pair,
                  rate: _rateForPair(rates, pair),
                ),
              )
              .toList(growable: false);
        },
      );
}

ExchangeRate? _rateForPair(List<ExchangeRate> rates, ExchangeRatePairRef pair) {
  for (final rate in rates) {
    if (rate.baseCurrencyCode == pair.base.value &&
        rate.quoteCurrencyCode == pair.quote.value) {
      return rate;
    }
  }
  return null;
}

@riverpod
class ExchangeRateRefresh extends _$ExchangeRateRefresh {
  @override
  FutureOr<void> build() {}

  Future<String?> refresh() async {
    final isOnline = await ref.read(connectivityProvider.future);
    if (!isOnline) {
      return 'Connect to the internet to refresh rates.';
    }

    state = const AsyncLoading();
    final result = await ref.read(refreshExchangeRatesUseCaseProvider)();

    return result.fold(
      (failure) {
        state = AsyncError(failure, StackTrace.current);
        return failure.message;
      },
      (refreshResult) {
        state = const AsyncData(null);
        ref.invalidate(exchangeRatesLastUpdatedProvider);
        if (refreshResult.updatedPairCount == 0 &&
            refreshResult.skippedManualPairCount > 0) {
          return 'All auto-fetched pairs are set manually. Edit a rate or clear manual overrides to refresh.';
        }
        return null;
      },
    );
  }
}
