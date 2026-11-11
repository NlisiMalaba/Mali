// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budget_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(currentMonthBudgets)
final currentMonthBudgetsProvider = CurrentMonthBudgetsProvider._();

final class CurrentMonthBudgetsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Budget>>,
          List<Budget>,
          Stream<List<Budget>>
        >
    with $FutureModifier<List<Budget>>, $StreamProvider<List<Budget>> {
  CurrentMonthBudgetsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentMonthBudgetsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentMonthBudgetsHash();

  @$internal
  @override
  $StreamProviderElement<List<Budget>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Budget>> create(Ref ref) {
    return currentMonthBudgets(ref);
  }
}

String _$currentMonthBudgetsHash() =>
    r'87b8f33b0e1f7a4427f70bef2a6aa11564f9996b';

@ProviderFor(budgetsForMonth)
final budgetsForMonthProvider = BudgetsForMonthFamily._();

final class BudgetsForMonthProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Budget>>,
          List<Budget>,
          Stream<List<Budget>>
        >
    with $FutureModifier<List<Budget>>, $StreamProvider<List<Budget>> {
  BudgetsForMonthProvider._({
    required BudgetsForMonthFamily super.from,
    required CategoryMonthQuery super.argument,
  }) : super(
         retry: null,
         name: r'budgetsForMonthProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$budgetsForMonthHash();

  @override
  String toString() {
    return r'budgetsForMonthProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<Budget>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Budget>> create(Ref ref) {
    final argument = this.argument as CategoryMonthQuery;
    return budgetsForMonth(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is BudgetsForMonthProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$budgetsForMonthHash() => r'4825875eb96aaaa824895e5c7d2c05da7e2cd61a';

final class BudgetsForMonthFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Budget>>, CategoryMonthQuery> {
  BudgetsForMonthFamily._()
    : super(
        retry: null,
        name: r'budgetsForMonthProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  BudgetsForMonthProvider call(CategoryMonthQuery query) =>
      BudgetsForMonthProvider._(argument: query, from: this);

  @override
  String toString() => r'budgetsForMonthProvider';
}

@ProviderFor(categoryMonthBudget)
final categoryMonthBudgetProvider = CategoryMonthBudgetFamily._();

final class CategoryMonthBudgetProvider
    extends $FunctionalProvider<AsyncValue<Budget?>, Budget?, Stream<Budget?>>
    with $FutureModifier<Budget?>, $StreamProvider<Budget?> {
  CategoryMonthBudgetProvider._({
    required CategoryMonthBudgetFamily super.from,
    required CategoryMonthQuery super.argument,
  }) : super(
         retry: null,
         name: r'categoryMonthBudgetProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$categoryMonthBudgetHash();

  @override
  String toString() {
    return r'categoryMonthBudgetProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Budget?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Budget?> create(Ref ref) {
    final argument = this.argument as CategoryMonthQuery;
    return categoryMonthBudget(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CategoryMonthBudgetProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$categoryMonthBudgetHash() =>
    r'14a9d19d51b1a2026e745f23a5f1823b740608cd';

final class CategoryMonthBudgetFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Budget?>, CategoryMonthQuery> {
  CategoryMonthBudgetFamily._()
    : super(
        retry: null,
        name: r'categoryMonthBudgetProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CategoryMonthBudgetProvider call(CategoryMonthQuery query) =>
      CategoryMonthBudgetProvider._(argument: query, from: this);

  @override
  String toString() => r'categoryMonthBudgetProvider';
}
