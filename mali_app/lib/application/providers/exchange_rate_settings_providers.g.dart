// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exchange_rate_settings_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(exchangeRateSettingsItems)
final exchangeRateSettingsItemsProvider = ExchangeRateSettingsItemsProvider._();

final class ExchangeRateSettingsItemsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ExchangeRateSettingsItem>>,
          List<ExchangeRateSettingsItem>,
          Stream<List<ExchangeRateSettingsItem>>
        >
    with
        $FutureModifier<List<ExchangeRateSettingsItem>>,
        $StreamProvider<List<ExchangeRateSettingsItem>> {
  ExchangeRateSettingsItemsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exchangeRateSettingsItemsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exchangeRateSettingsItemsHash();

  @$internal
  @override
  $StreamProviderElement<List<ExchangeRateSettingsItem>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<ExchangeRateSettingsItem>> create(Ref ref) {
    return exchangeRateSettingsItems(ref);
  }
}

String _$exchangeRateSettingsItemsHash() =>
    r'423289d303ebec7f1dc36d6281cb74706cde4a0f';

@ProviderFor(ExchangeRateRefresh)
final exchangeRateRefreshProvider = ExchangeRateRefreshProvider._();

final class ExchangeRateRefreshProvider
    extends $AsyncNotifierProvider<ExchangeRateRefresh, void> {
  ExchangeRateRefreshProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exchangeRateRefreshProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exchangeRateRefreshHash();

  @$internal
  @override
  ExchangeRateRefresh create() => ExchangeRateRefresh();
}

String _$exchangeRateRefreshHash() =>
    r'882ee589292e00778e78a5505facf3343a24c6e1';

abstract class _$ExchangeRateRefresh extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
