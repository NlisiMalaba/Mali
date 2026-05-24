// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gateway_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(remoteSyncPushGateway)
final remoteSyncPushGatewayProvider = RemoteSyncPushGatewayProvider._();

final class RemoteSyncPushGatewayProvider
    extends
        $FunctionalProvider<
          remote_sync.ISyncPushGateway,
          remote_sync.ISyncPushGateway,
          remote_sync.ISyncPushGateway
        >
    with $Provider<remote_sync.ISyncPushGateway> {
  RemoteSyncPushGatewayProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'remoteSyncPushGatewayProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$remoteSyncPushGatewayHash();

  @$internal
  @override
  $ProviderElement<remote_sync.ISyncPushGateway> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  remote_sync.ISyncPushGateway create(Ref ref) {
    return remoteSyncPushGateway(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(remote_sync.ISyncPushGateway value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<remote_sync.ISyncPushGateway>(value),
    );
  }
}

String _$remoteSyncPushGatewayHash() =>
    r'2fa5bcceffddf5aaf544b1679380495582d87b50';

@ProviderFor(syncPullGateway)
final syncPullGatewayProvider = SyncPullGatewayProvider._();

final class SyncPullGatewayProvider
    extends
        $FunctionalProvider<
          ISyncPullGateway,
          ISyncPullGateway,
          ISyncPullGateway
        >
    with $Provider<ISyncPullGateway> {
  SyncPullGatewayProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncPullGatewayProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncPullGatewayHash();

  @$internal
  @override
  $ProviderElement<ISyncPullGateway> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ISyncPullGateway create(Ref ref) {
    return syncPullGateway(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ISyncPullGateway value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ISyncPullGateway>(value),
    );
  }
}

String _$syncPullGatewayHash() => r'd0a59c5518b6d7e0ddae2d4cfe9e9ac85eccf6eb';

@ProviderFor(transactionSyncPushGateway)
final transactionSyncPushGatewayProvider =
    TransactionSyncPushGatewayProvider._();

final class TransactionSyncPushGatewayProvider
    extends
        $FunctionalProvider<
          ISyncPushGateway,
          ISyncPushGateway,
          ISyncPushGateway
        >
    with $Provider<ISyncPushGateway> {
  TransactionSyncPushGatewayProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transactionSyncPushGatewayProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transactionSyncPushGatewayHash();

  @$internal
  @override
  $ProviderElement<ISyncPushGateway> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ISyncPushGateway create(Ref ref) {
    return transactionSyncPushGateway(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ISyncPushGateway value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ISyncPushGateway>(value),
    );
  }
}

String _$transactionSyncPushGatewayHash() =>
    r'80e46040584662401cb9e688993be14916bd85c9';
