// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recent_wallets_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(recentWalletStore)
final recentWalletStoreProvider = RecentWalletStoreProvider._();

final class RecentWalletStoreProvider
    extends
        $FunctionalProvider<
          RecentWalletStore,
          RecentWalletStore,
          RecentWalletStore
        >
    with $Provider<RecentWalletStore> {
  RecentWalletStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recentWalletStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recentWalletStoreHash();

  @$internal
  @override
  $ProviderElement<RecentWalletStore> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RecentWalletStore create(Ref ref) {
    return recentWalletStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecentWalletStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RecentWalletStore>(value),
    );
  }
}

String _$recentWalletStoreHash() => r'191a4ce756de00a4d5850024d4bc9c2dd732993b';

@ProviderFor(RecentWallets)
final recentWalletsProvider = RecentWalletsProvider._();

final class RecentWalletsProvider
    extends $AsyncNotifierProvider<RecentWallets, List<String>> {
  RecentWalletsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recentWalletsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recentWalletsHash();

  @$internal
  @override
  RecentWallets create() => RecentWallets();
}

String _$recentWalletsHash() => r'528a6a28acc0c505c95b35e0c853c7a269eec395';

abstract class _$RecentWallets extends $AsyncNotifier<List<String>> {
  FutureOr<List<String>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<String>>, List<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<String>>, List<String>>,
              AsyncValue<List<String>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(recentWalletIds)
final recentWalletIdsProvider = RecentWalletIdsProvider._();

final class RecentWalletIdsProvider
    extends $FunctionalProvider<List<String>, List<String>, List<String>>
    with $Provider<List<String>> {
  RecentWalletIdsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recentWalletIdsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recentWalletIdsHash();

  @$internal
  @override
  $ProviderElement<List<String>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<String> create(Ref ref) {
    return recentWalletIds(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<String>>(value),
    );
  }
}

String _$recentWalletIdsHash() => r'9aae349b68153ba13c7d796b449fac00b4b9a026';

@ProviderFor(defaultWalletId)
final defaultWalletIdProvider = DefaultWalletIdFamily._();

final class DefaultWalletIdProvider
    extends $FunctionalProvider<String?, String?, String?>
    with $Provider<String?> {
  DefaultWalletIdProvider._({
    required DefaultWalletIdFamily super.from,
    required DefaultWalletKey super.argument,
  }) : super(
         retry: null,
         name: r'defaultWalletIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$defaultWalletIdHash();

  @override
  String toString() {
    return r'defaultWalletIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String? create(Ref ref) {
    final argument = this.argument as DefaultWalletKey;
    return defaultWalletId(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DefaultWalletIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$defaultWalletIdHash() => r'4d423a513d46deacdde59cce00c4869dd3bf032b';

final class DefaultWalletIdFamily extends $Family
    with $FunctionalFamilyOverride<String?, DefaultWalletKey> {
  DefaultWalletIdFamily._()
    : super(
        retry: null,
        name: r'defaultWalletIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  DefaultWalletIdProvider call(DefaultWalletKey key) =>
      DefaultWalletIdProvider._(argument: key, from: this);

  @override
  String toString() => r'defaultWalletIdProvider';
}
