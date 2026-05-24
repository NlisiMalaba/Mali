import 'package:mali_app/domain/value_objects/currency_code.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'display_currency_provider.g.dart';

/// User's preferred currency for displaying equivalents and net worth.
///
/// TODO(settings-31): Load from persisted user preferences.
@Riverpod(keepAlive: true)
CurrencyCode displayCurrency(Ref ref) {
  return CurrencyCode.usd;
}
