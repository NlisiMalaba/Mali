// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analytics_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(analyticsOverview)
final analyticsOverviewProvider = AnalyticsOverviewProvider._();

final class AnalyticsOverviewProvider
    extends
        $FunctionalProvider<
          AsyncValue<AnalyticsOverview>,
          AnalyticsOverview,
          FutureOr<AnalyticsOverview>
        >
    with
        $FutureModifier<AnalyticsOverview>,
        $FutureProvider<AnalyticsOverview> {
  AnalyticsOverviewProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'analyticsOverviewProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$analyticsOverviewHash();

  @$internal
  @override
  $FutureProviderElement<AnalyticsOverview> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<AnalyticsOverview> create(Ref ref) {
    return analyticsOverview(ref);
  }
}

String _$analyticsOverviewHash() => r'7f35b8abaf69d5df41f2212aa6716df6c4d5cf8d';

@ProviderFor(categoryMonthTransactions)
final categoryMonthTransactionsProvider = CategoryMonthTransactionsFamily._();

final class CategoryMonthTransactionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Transaction>>,
          List<Transaction>,
          Stream<List<Transaction>>
        >
    with
        $FutureModifier<List<Transaction>>,
        $StreamProvider<List<Transaction>> {
  CategoryMonthTransactionsProvider._({
    required CategoryMonthTransactionsFamily super.from,
    required CategoryMonthQuery super.argument,
  }) : super(
         retry: null,
         name: r'categoryMonthTransactionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$categoryMonthTransactionsHash();

  @override
  String toString() {
    return r'categoryMonthTransactionsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<Transaction>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Transaction>> create(Ref ref) {
    final argument = this.argument as CategoryMonthQuery;
    return categoryMonthTransactions(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CategoryMonthTransactionsProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$categoryMonthTransactionsHash() =>
    r'dd14af493ff3c5b3da5e0005167e08a96b14bffa';

final class CategoryMonthTransactionsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          Stream<List<Transaction>>,
          CategoryMonthQuery
        > {
  CategoryMonthTransactionsFamily._()
    : super(
        retry: null,
        name: r'categoryMonthTransactionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CategoryMonthTransactionsProvider call(CategoryMonthQuery query) =>
      CategoryMonthTransactionsProvider._(argument: query, from: this);

  @override
  String toString() => r'categoryMonthTransactionsProvider';
}

@ProviderFor(categoryMonthDisplayTotal)
final categoryMonthDisplayTotalProvider = CategoryMonthDisplayTotalFamily._();

final class CategoryMonthDisplayTotalProvider
    extends $FunctionalProvider<AsyncValue<Money>, Money, FutureOr<Money>>
    with $FutureModifier<Money>, $FutureProvider<Money> {
  CategoryMonthDisplayTotalProvider._({
    required CategoryMonthDisplayTotalFamily super.from,
    required CategoryMonthQuery super.argument,
  }) : super(
         retry: null,
         name: r'categoryMonthDisplayTotalProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$categoryMonthDisplayTotalHash();

  @override
  String toString() {
    return r'categoryMonthDisplayTotalProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Money> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Money> create(Ref ref) {
    final argument = this.argument as CategoryMonthQuery;
    return categoryMonthDisplayTotal(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CategoryMonthDisplayTotalProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$categoryMonthDisplayTotalHash() =>
    r'6b50f29977c02a10fdf42d01120111c0d78d9b3b';

final class CategoryMonthDisplayTotalFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Money>, CategoryMonthQuery> {
  CategoryMonthDisplayTotalFamily._()
    : super(
        retry: null,
        name: r'categoryMonthDisplayTotalProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CategoryMonthDisplayTotalProvider call(CategoryMonthQuery query) =>
      CategoryMonthDisplayTotalProvider._(argument: query, from: this);

  @override
  String toString() => r'categoryMonthDisplayTotalProvider';
}

@ProviderFor(analyticsTrends)
final analyticsTrendsProvider = AnalyticsTrendsProvider._();

final class AnalyticsTrendsProvider
    extends
        $FunctionalProvider<
          AsyncValue<AnalyticsTrends>,
          AnalyticsTrends,
          FutureOr<AnalyticsTrends>
        >
    with $FutureModifier<AnalyticsTrends>, $FutureProvider<AnalyticsTrends> {
  AnalyticsTrendsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'analyticsTrendsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$analyticsTrendsHash();

  @$internal
  @override
  $FutureProviderElement<AnalyticsTrends> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<AnalyticsTrends> create(Ref ref) {
    return analyticsTrends(ref);
  }
}

String _$analyticsTrendsHash() => r'9b5c54fcf5bbe0b6a35d1198e1f6f4d41153d452';

@ProviderFor(TrendsDisabledCurrencies)
final trendsDisabledCurrenciesProvider = TrendsDisabledCurrenciesProvider._();

final class TrendsDisabledCurrenciesProvider
    extends $NotifierProvider<TrendsDisabledCurrencies, List<String>> {
  TrendsDisabledCurrenciesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'trendsDisabledCurrenciesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$trendsDisabledCurrenciesHash();

  @$internal
  @override
  TrendsDisabledCurrencies create() => TrendsDisabledCurrencies();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<String>>(value),
    );
  }
}

String _$trendsDisabledCurrenciesHash() =>
    r'86af0aa5158f1f905f866a2d54fafbf007a6fec1';

abstract class _$TrendsDisabledCurrencies extends $Notifier<List<String>> {
  List<String> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<String>, List<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<String>, List<String>>,
              List<String>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
