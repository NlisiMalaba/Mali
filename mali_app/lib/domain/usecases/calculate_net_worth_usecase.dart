import 'package:decimal/decimal.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mali_app/core/error/failure.dart';
import 'package:mali_app/domain/entities/wallet.dart';
import 'package:mali_app/domain/repositories/wallet_repository.dart';
import 'package:mali_app/domain/value_objects/currency_code.dart';
import 'package:mali_app/domain/value_objects/money.dart';

/// Sums wallet balances in their own currencies — never mixes via FX.
class CalculateNetWorthUseCase {
  const CalculateNetWorthUseCase({
    required IWalletRepository walletRepository,
  }) : _walletRepository = walletRepository;

  final IWalletRepository _walletRepository;

  Future<Either<Failure, CalculateNetWorthResult>> call() async {
    final wallets = await _walletRepository.watchActive().first;
    final totals = <CurrencyCode, Decimal>{};
    final breakdown = <WalletBalanceBreakdown>[];

    for (final wallet in wallets) {
      final currency = CurrencyCode(wallet.currencyCode);
      final amount = _parseDecimal(wallet.balance);
      if (amount == null) {
        return left(
          StorageFailure(
            message: 'Wallet balance is invalid for wallet ${wallet.id}.',
          ),
        );
      }

      totals[currency] = (totals[currency] ?? Decimal.zero) + amount;
      breakdown.add(WalletBalanceBreakdown(wallet: wallet));
    }

    final totalsByCurrency = [
      for (final currency in CurrencyCode.values)
        if (totals.containsKey(currency))
          Money(amount: totals[currency]!, currency: currency),
      for (final entry in totals.entries)
        if (!CurrencyCode.values.contains(entry.key))
          Money(amount: entry.value, currency: entry.key),
    ];

    return right(
      CalculateNetWorthResult(
        totalsByCurrency: totalsByCurrency,
        walletBreakdown: breakdown,
      ),
    );
  }

  Decimal? _parseDecimal(String value) {
    try {
      return Decimal.parse(value);
    } catch (_) {
      return null;
    }
  }
}

class CalculateNetWorthResult {
  const CalculateNetWorthResult({
    required this.totalsByCurrency,
    required this.walletBreakdown,
  });

  /// Native total per currency that has at least one wallet. No FX conversion.
  final List<Money> totalsByCurrency;
  final List<WalletBalanceBreakdown> walletBreakdown;

  Money? totalFor(CurrencyCode currency) {
    for (final total in totalsByCurrency) {
      if (total.currency == currency) {
        return total;
      }
    }
    return null;
  }
}

class WalletBalanceBreakdown {
  const WalletBalanceBreakdown({required this.wallet});

  final Wallet wallet;
}
