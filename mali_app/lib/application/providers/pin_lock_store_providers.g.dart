// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pin_lock_store_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(pinLockStore)
final pinLockStoreProvider = PinLockStoreProvider._();

final class PinLockStoreProvider
    extends $FunctionalProvider<IPinLockStore, IPinLockStore, IPinLockStore>
    with $Provider<IPinLockStore> {
  PinLockStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pinLockStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pinLockStoreHash();

  @$internal
  @override
  $ProviderElement<IPinLockStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  IPinLockStore create(Ref ref) {
    return pinLockStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IPinLockStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IPinLockStore>(value),
    );
  }
}

String _$pinLockStoreHash() => r'56870e991a3257aade53e105dedd80e9f353a068';

@ProviderFor(pinLockRepository)
final pinLockRepositoryProvider = PinLockRepositoryProvider._();

final class PinLockRepositoryProvider
    extends
        $FunctionalProvider<
          IPinLockRepository,
          IPinLockRepository,
          IPinLockRepository
        >
    with $Provider<IPinLockRepository> {
  PinLockRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pinLockRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pinLockRepositoryHash();

  @$internal
  @override
  $ProviderElement<IPinLockRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  IPinLockRepository create(Ref ref) {
    return pinLockRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IPinLockRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IPinLockRepository>(value),
    );
  }
}

String _$pinLockRepositoryHash() => r'474fcb1cdedd3ffa53cb66997557256decd2fc2c';
