// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recent_categories_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(recentCategoryStore)
final recentCategoryStoreProvider = RecentCategoryStoreProvider._();

final class RecentCategoryStoreProvider
    extends
        $FunctionalProvider<
          RecentCategoryStore,
          RecentCategoryStore,
          RecentCategoryStore
        >
    with $Provider<RecentCategoryStore> {
  RecentCategoryStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recentCategoryStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recentCategoryStoreHash();

  @$internal
  @override
  $ProviderElement<RecentCategoryStore> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RecentCategoryStore create(Ref ref) {
    return recentCategoryStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecentCategoryStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RecentCategoryStore>(value),
    );
  }
}

String _$recentCategoryStoreHash() =>
    r'58023864a8fe94afc283d076157d38d212280421';

@ProviderFor(RecentCategories)
final recentCategoriesProvider = RecentCategoriesProvider._();

final class RecentCategoriesProvider
    extends
        $AsyncNotifierProvider<RecentCategories, Map<String, List<String>>> {
  RecentCategoriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recentCategoriesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recentCategoriesHash();

  @$internal
  @override
  RecentCategories create() => RecentCategories();
}

String _$recentCategoriesHash() => r'ac37afb681eff07edbd522e6290a2334d41b38e9';

abstract class _$RecentCategories
    extends $AsyncNotifier<Map<String, List<String>>> {
  FutureOr<Map<String, List<String>>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<Map<String, List<String>>>,
              Map<String, List<String>>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<Map<String, List<String>>>,
                Map<String, List<String>>
              >,
              AsyncValue<Map<String, List<String>>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(recentCategoryIds)
final recentCategoryIdsProvider = RecentCategoryIdsFamily._();

final class RecentCategoryIdsProvider
    extends $FunctionalProvider<List<String>, List<String>, List<String>>
    with $Provider<List<String>> {
  RecentCategoryIdsProvider._({
    required RecentCategoryIdsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'recentCategoryIdsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$recentCategoryIdsHash();

  @override
  String toString() {
    return r'recentCategoryIdsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<List<String>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<String> create(Ref ref) {
    final argument = this.argument as String;
    return recentCategoryIds(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<String>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is RecentCategoryIdsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$recentCategoryIdsHash() => r'b86c4c89a98aaf880232a70f04fb995ad25406c4';

final class RecentCategoryIdsFamily extends $Family
    with $FunctionalFamilyOverride<List<String>, String> {
  RecentCategoryIdsFamily._()
    : super(
        retry: null,
        name: r'recentCategoryIdsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  RecentCategoryIdsProvider call(String type) =>
      RecentCategoryIdsProvider._(argument: type, from: this);

  @override
  String toString() => r'recentCategoryIdsProvider';
}
