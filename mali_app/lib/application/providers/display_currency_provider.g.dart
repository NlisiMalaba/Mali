// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'display_currency_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// User's preferred currency for displaying equivalents and net worth.
///
/// TODO(settings-31): Load from persisted user preferences.

@ProviderFor(displayCurrency)
final displayCurrencyProvider = DisplayCurrencyProvider._();

/// User's preferred currency for displaying equivalents and net worth.
///
/// TODO(settings-31): Load from persisted user preferences.

final class DisplayCurrencyProvider
    extends $FunctionalProvider<CurrencyCode, CurrencyCode, CurrencyCode>
    with $Provider<CurrencyCode> {
  /// User's preferred currency for displaying equivalents and net worth.
  ///
  /// TODO(settings-31): Load from persisted user preferences.
  DisplayCurrencyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'displayCurrencyProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$displayCurrencyHash();

  @$internal
  @override
  $ProviderElement<CurrencyCode> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CurrencyCode create(Ref ref) {
    return displayCurrency(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CurrencyCode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CurrencyCode>(value),
    );
  }
}

String _$displayCurrencyHash() => r'70c31d2aa6419ed637a678a46c349c5d87fe06c7';
