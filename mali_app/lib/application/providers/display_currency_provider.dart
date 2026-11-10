import 'package:mali_app/application/providers/app_preferences_provider.dart';
import 'package:mali_app/domain/value_objects/currency_code.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'display_currency_provider.g.dart';

/// User's preferred currency for displaying equivalents and net worth.
@Riverpod(keepAlive: true)
CurrencyCode displayCurrency(Ref ref) {
  return ref.watch(appPreferencesProvider).displayCurrency;
}
