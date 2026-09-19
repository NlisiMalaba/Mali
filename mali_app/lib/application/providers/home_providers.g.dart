// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(homeNetWorth)
final homeNetWorthProvider = HomeNetWorthProvider._();

final class HomeNetWorthProvider
    extends
        $FunctionalProvider<
          AsyncValue<CalculateNetWorthResult>,
          CalculateNetWorthResult,
          FutureOr<CalculateNetWorthResult>
        >
    with
        $FutureModifier<CalculateNetWorthResult>,
        $FutureProvider<CalculateNetWorthResult> {
  HomeNetWorthProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeNetWorthProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeNetWorthHash();

  @$internal
  @override
  $FutureProviderElement<CalculateNetWorthResult> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CalculateNetWorthResult> create(Ref ref) {
    return homeNetWorth(ref);
  }
}

String _$homeNetWorthHash() => r'bb8b8f1446dafc317c69836982598315d64c36a8';

@ProviderFor(HomeSelectedMonth)
final homeSelectedMonthProvider = HomeSelectedMonthProvider._();

final class HomeSelectedMonthProvider
    extends $NotifierProvider<HomeSelectedMonth, DateTime> {
  HomeSelectedMonthProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeSelectedMonthProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeSelectedMonthHash();

  @$internal
  @override
  HomeSelectedMonth create() => HomeSelectedMonth();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime>(value),
    );
  }
}

String _$homeSelectedMonthHash() => r'5174069e59d7fb88748d423f5453a58e29b82f4d';

abstract class _$HomeSelectedMonth extends $Notifier<DateTime> {
  DateTime build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<DateTime, DateTime>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DateTime, DateTime>,
              DateTime,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(homeMonthlySummaryDisplay)
final homeMonthlySummaryDisplayProvider = HomeMonthlySummaryDisplayProvider._();

final class HomeMonthlySummaryDisplayProvider
    extends
        $FunctionalProvider<
          AsyncValue<HomeMonthlySummaryDisplay>,
          HomeMonthlySummaryDisplay,
          FutureOr<HomeMonthlySummaryDisplay>
        >
    with
        $FutureModifier<HomeMonthlySummaryDisplay>,
        $FutureProvider<HomeMonthlySummaryDisplay> {
  HomeMonthlySummaryDisplayProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeMonthlySummaryDisplayProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeMonthlySummaryDisplayHash();

  @$internal
  @override
  $FutureProviderElement<HomeMonthlySummaryDisplay> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<HomeMonthlySummaryDisplay> create(Ref ref) {
    return homeMonthlySummaryDisplay(ref);
  }
}

String _$homeMonthlySummaryDisplayHash() =>
    r'2035c391e1b63a105cafaa4e9078697f7511fcc9';

@ProviderFor(homeRecentTransactions)
final homeRecentTransactionsProvider = HomeRecentTransactionsProvider._();

final class HomeRecentTransactionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Transaction>>,
          List<Transaction>,
          Stream<List<Transaction>>
        >
    with
        $FutureModifier<List<Transaction>>,
        $StreamProvider<List<Transaction>> {
  HomeRecentTransactionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeRecentTransactionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeRecentTransactionsHash();

  @$internal
  @override
  $StreamProviderElement<List<Transaction>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Transaction>> create(Ref ref) {
    return homeRecentTransactions(ref);
  }
}

String _$homeRecentTransactionsHash() =>
    r'127cb3e4a5c19b52287a0338242c4c77ba5c0836';

@ProviderFor(homeTopBudgets)
final homeTopBudgetsProvider = HomeTopBudgetsProvider._();

final class HomeTopBudgetsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Budget>>,
          List<Budget>,
          Stream<List<Budget>>
        >
    with $FutureModifier<List<Budget>>, $StreamProvider<List<Budget>> {
  HomeTopBudgetsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeTopBudgetsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeTopBudgetsHash();

  @$internal
  @override
  $StreamProviderElement<List<Budget>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Budget>> create(Ref ref) {
    return homeTopBudgets(ref);
  }
}

String _$homeTopBudgetsHash() => r'065ad8f97270e01d0bd69b96d2a1a2f715db79fa';

@ProviderFor(homeTopGoals)
final homeTopGoalsProvider = HomeTopGoalsProvider._();

final class HomeTopGoalsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SavingsGoal>>,
          List<SavingsGoal>,
          Stream<List<SavingsGoal>>
        >
    with
        $FutureModifier<List<SavingsGoal>>,
        $StreamProvider<List<SavingsGoal>> {
  HomeTopGoalsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeTopGoalsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeTopGoalsHash();

  @$internal
  @override
  $StreamProviderElement<List<SavingsGoal>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<SavingsGoal>> create(Ref ref) {
    return homeTopGoals(ref);
  }
}

String _$homeTopGoalsHash() => r'a87ac170267894ef42e0c99a976aff46fdc1baa4';

@ProviderFor(exchangeRatesLastUpdated)
final exchangeRatesLastUpdatedProvider = ExchangeRatesLastUpdatedProvider._();

final class ExchangeRatesLastUpdatedProvider
    extends
        $FunctionalProvider<AsyncValue<DateTime?>, DateTime?, Stream<DateTime?>>
    with $FutureModifier<DateTime?>, $StreamProvider<DateTime?> {
  ExchangeRatesLastUpdatedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exchangeRatesLastUpdatedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exchangeRatesLastUpdatedHash();

  @$internal
  @override
  $StreamProviderElement<DateTime?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<DateTime?> create(Ref ref) {
    return exchangeRatesLastUpdated(ref);
  }
}

String _$exchangeRatesLastUpdatedHash() =>
    r'98affbbf6c2cb99de47f1098094aa32c8e8fb06a';
