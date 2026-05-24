// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(lastSyncStore)
final lastSyncStoreProvider = LastSyncStoreProvider._();

final class LastSyncStoreProvider
    extends $FunctionalProvider<LastSyncStore, LastSyncStore, LastSyncStore>
    with $Provider<LastSyncStore> {
  LastSyncStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lastSyncStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lastSyncStoreHash();

  @$internal
  @override
  $ProviderElement<LastSyncStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LastSyncStore create(Ref ref) {
    return lastSyncStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LastSyncStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LastSyncStore>(value),
    );
  }
}

String _$lastSyncStoreHash() => r'1f3e57df985cdeb608b6ad211ac95e88a5f785fb';

@ProviderFor(syncQueueManager)
final syncQueueManagerProvider = SyncQueueManagerProvider._();

final class SyncQueueManagerProvider
    extends
        $FunctionalProvider<
          SyncQueueManager,
          SyncQueueManager,
          SyncQueueManager
        >
    with $Provider<SyncQueueManager> {
  SyncQueueManagerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncQueueManagerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncQueueManagerHash();

  @$internal
  @override
  $ProviderElement<SyncQueueManager> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SyncQueueManager create(Ref ref) {
    return syncQueueManager(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SyncQueueManager value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SyncQueueManager>(value),
    );
  }
}

String _$syncQueueManagerHash() => r'1bca9100dcb095db259703aefd661b69246fe3f2';

@ProviderFor(backgroundSyncService)
final backgroundSyncServiceProvider = BackgroundSyncServiceProvider._();

final class BackgroundSyncServiceProvider
    extends
        $FunctionalProvider<
          BackgroundSyncService,
          BackgroundSyncService,
          BackgroundSyncService
        >
    with $Provider<BackgroundSyncService> {
  BackgroundSyncServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'backgroundSyncServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$backgroundSyncServiceHash();

  @$internal
  @override
  $ProviderElement<BackgroundSyncService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BackgroundSyncService create(Ref ref) {
    return backgroundSyncService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BackgroundSyncService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BackgroundSyncService>(value),
    );
  }
}

String _$backgroundSyncServiceHash() =>
    r'25c43be1580602154e6f9cfb66513d7a165e6cd5';

@ProviderFor(syncBootstrap)
final syncBootstrapProvider = SyncBootstrapProvider._();

final class SyncBootstrapProvider
    extends $FunctionalProvider<SyncBootstrap, SyncBootstrap, SyncBootstrap>
    with $Provider<SyncBootstrap> {
  SyncBootstrapProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncBootstrapProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncBootstrapHash();

  @$internal
  @override
  $ProviderElement<SyncBootstrap> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SyncBootstrap create(Ref ref) {
    return syncBootstrap(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SyncBootstrap value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SyncBootstrap>(value),
    );
  }
}

String _$syncBootstrapHash() => r'a11e1770c8b468084e75ddfcbfd8da1096c428c1';
