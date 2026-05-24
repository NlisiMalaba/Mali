import 'package:fpdart/fpdart.dart';
import 'package:mali_app/core/error/failure.dart';
import 'package:mali_app/core/utils/local_id_generator.dart';
import 'package:mali_app/domain/entities/exchange_rate.dart';
import 'package:mali_app/domain/repositories/exchange_rate_fetcher.dart';
import 'package:mali_app/domain/repositories/exchange_rate_repository.dart';
import 'package:mali_app/domain/services/exchange_rate_math.dart';
import 'package:mali_app/domain/value_objects/currency_code.dart';

class RefreshExchangeRatesResult {
  const RefreshExchangeRatesResult({
    required this.updatedPairCount,
    required this.skippedManualPairCount,
  });

  final int updatedPairCount;
  final int skippedManualPairCount;
}

class RefreshExchangeRatesUseCase {
  const RefreshExchangeRatesUseCase({
    required IExchangeRateRepository exchangeRateRepository,
    required IExchangeRateFetcher exchangeRateFetcher,
  })  : _exchangeRateRepository = exchangeRateRepository,
        _exchangeRateFetcher = exchangeRateFetcher;

  final IExchangeRateRepository _exchangeRateRepository;
  final IExchangeRateFetcher _exchangeRateFetcher;

  Future<Either<Failure, RefreshExchangeRatesResult>> call() async {
    final fetchResult = await _exchangeRateFetcher.fetchLatestRates();
    if (fetchResult.isLeft()) {
      return left(fetchResult.getLeft().toNullable()!);
    }

    var updatedPairCount = 0;
    var skippedManualPairCount = 0;

    for (final fetched in fetchResult.getOrElse((_) => throw StateError('expected right'))) {
      final directResult = await _upsertAutoRate(
        base: fetched.base,
        quote: fetched.quote,
        rate: fetched.rate,
      );
      if (directResult.isLeft()) {
        return left(directResult.getLeft().toNullable()!);
      }
      switch (directResult.getOrElse((_) => throw StateError('expected right'))) {
        case _UpsertOutcome.skippedManual:
          skippedManualPairCount++;
        case _UpsertOutcome.updated:
          updatedPairCount++;
        case _UpsertOutcome.failed:
          return left(
            const ValidationFailure(
              message: 'Fetched rate is invalid.',
              field: 'rate',
            ),
          );
      }

      final inverseRate = ExchangeRateMath.invertRateString(fetched.rate);
      if (inverseRate == null) {
        return left(
          const ValidationFailure(
            message: 'Fetched rate could not be inverted for the reverse pair.',
            field: 'rate',
          ),
        );
      }

      final inverseResult = await _upsertAutoRate(
        base: fetched.quote,
        quote: fetched.base,
        rate: inverseRate,
      );
      if (inverseResult.isLeft()) {
        return left(inverseResult.getLeft().toNullable()!);
      }
      switch (inverseResult.getOrElse((_) => throw StateError('expected right'))) {
        case _UpsertOutcome.skippedManual:
          skippedManualPairCount++;
        case _UpsertOutcome.updated:
          updatedPairCount++;
        case _UpsertOutcome.failed:
          return left(
            const ValidationFailure(
              message: 'Inverted rate is invalid.',
              field: 'rate',
            ),
          );
      }
    }

    return right(
      RefreshExchangeRatesResult(
        updatedPairCount: updatedPairCount,
        skippedManualPairCount: skippedManualPairCount,
      ),
    );
  }

  Future<Either<Failure, _UpsertOutcome>> _upsertAutoRate({
    required CurrencyCode base,
    required CurrencyCode quote,
    required String rate,
  }) async {
    final existing = await _exchangeRateRepository.getRate(
      baseCurrencyCode: base,
      quoteCurrencyCode: quote,
    );
    if (existing?.isManual == true) {
      return right(_UpsertOutcome.skippedManual);
    }

    final parsedRate = ExchangeRateMath.parsePositiveRate(rate);
    if (parsedRate == null) {
      return right(_UpsertOutcome.failed);
    }

    final now = DateTime.now().toUtc();
    final entry = ExchangeRate(
      id: existing?.id ?? LocalIdGenerator.newId('rate'),
      baseCurrencyCode: base.value,
      quoteCurrencyCode: quote.value,
      rate: parsedRate.toString(),
      isManual: false,
      rateDate: now,
      isSynced: false,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    try {
      await _exchangeRateRepository.save(entry);
    } catch (error) {
      return left(
        StorageFailure(
          message: 'Failed to save fetched exchange rate.',
          cause: error,
        ),
      );
    }

    return right(_UpsertOutcome.updated);
  }
}

enum _UpsertOutcome { updated, skippedManual, failed }
