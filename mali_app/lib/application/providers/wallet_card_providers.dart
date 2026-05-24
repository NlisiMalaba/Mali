import 'package:mali_app/application/providers/display_currency_provider.dart';
import 'package:mali_app/application/providers/use_case_providers.dart';
import 'package:mali_app/domain/value_objects/currency_code.dart';
import 'package:mali_app/domain/value_objects/money.dart';
import 'package:mali_app/presentation/utils/money_display.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'wallet_card_providers.g.dart';

typedef WalletEquivalentKey = ({String balance, String currencyCode});

@riverpod
Future<String?> walletEquivalentLabel(
  Ref ref,
  WalletEquivalentKey key,
) async {
  final displayCurrency = ref.watch(displayCurrencyProvider);
  final sourceCurrency = CurrencyCode(key.currencyCode);

  if (sourceCurrency == displayCurrency) {
    return null;
  }

  final Money sourceMoney;
  try {
    sourceMoney = Money.fromString(
      amount: key.balance,
      currency: sourceCurrency,
    );
  } catch (_) {
    return null;
  }

  final result = await ref.read(convertMoneyUseCaseProvider)(
    money: sourceMoney,
    targetCurrency: displayCurrency,
  );

  return result.fold(
    (_) => null,
    (converted) =>
        '≈ ${MoneyDisplay.withCurrency(
          amount: converted.amount.toString(),
          currencyCode: converted.currency.value,
        )}',
  );
}
