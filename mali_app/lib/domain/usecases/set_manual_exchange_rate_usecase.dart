import 'package:fpdart/fpdart.dart';
import 'package:mali_app/core/error/failure.dart';
import 'package:mali_app/core/utils/local_id_generator.dart';
import 'package:mali_app/domain/entities/exchange_rate.dart';
import 'package:mali_app/domain/repositories/exchange_rate_repository.dart';
import 'package:mali_app/domain/services/exchange_rate_math.dart';
import 'package:mali_app/domain/value_objects/currency_code.dart';

class SetManualExchangeRateParams {
  const SetManualExchangeRateParams({
    required this.baseCurrency,
    required this.quoteCurrency,
    required this.rate,
  });

  final CurrencyCode baseCurrency;
  final CurrencyCode quoteCurrency;
  final String rate;
}

class SetManualExchangeRateUseCase {
  const SetManualExchangeRateUseCase({
    required IExchangeRateRepository exchangeRateRepository,
  }) : _exchangeRateRepository = exchangeRateRepository;

  final IExchangeRateRepository _exchangeRateRepository;

  Future<Either<Failure, ExchangeRate>> call(
    SetManualExchangeRateParams params,
  ) async {
    if (params.baseCurrency == params.quoteCurrency) {
      return left(
        const ValidationFailure(
          message: 'Base and quote currencies must be different.',
          field: 'quoteCurrency',
        ),
      );
    }

    final parsedRate = ExchangeRateMath.parsePositiveRate(params.rate);
    if (parsedRate == null) {
      return left(
        const ValidationFailure(
          message: 'Enter a valid rate greater than zero.',
          field: 'rate',
        ),
      );
    }

    final existing = await _exchangeRateRepository.getRate(
      baseCurrencyCode: params.baseCurrency,
      quoteCurrencyCode: params.quoteCurrency,
    );

    final now = DateTime.now().toUtc();
    final rate = ExchangeRate(
      id: existing?.id ?? LocalIdGenerator.newId('rate'),
      baseCurrencyCode: params.baseCurrency.value,
      quoteCurrencyCode: params.quoteCurrency.value,
      rate: parsedRate.toString(),
      isManual: true,
      rateDate: now,
      isSynced: false,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    try {
      await _exchangeRateRepository.save(rate);
    } catch (error) {
      return left(
        StorageFailure(
          message: 'Failed to save exchange rate.',
          cause: error,
        ),
      );
    }

    return right(rate);
  }
}
