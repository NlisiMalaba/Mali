// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_store_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(authTokenStore)
final authTokenStoreProvider = AuthTokenStoreProvider._();

final class AuthTokenStoreProvider
    extends
        $FunctionalProvider<IAuthTokenStore, IAuthTokenStore, IAuthTokenStore>
    with $Provider<IAuthTokenStore> {
  AuthTokenStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authTokenStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authTokenStoreHash();

  @$internal
  @override
  $ProviderElement<IAuthTokenStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  IAuthTokenStore create(Ref ref) {
    return authTokenStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IAuthTokenStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IAuthTokenStore>(value),
    );
  }
}

String _$authTokenStoreHash() => r'80cf562f831789fc9143e6d22bee172c18e3936a';

@ProviderFor(authUserStore)
final authUserStoreProvider = AuthUserStoreProvider._();

final class AuthUserStoreProvider
    extends $FunctionalProvider<IAuthUserStore, IAuthUserStore, IAuthUserStore>
    with $Provider<IAuthUserStore> {
  AuthUserStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authUserStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authUserStoreHash();

  @$internal
  @override
  $ProviderElement<IAuthUserStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  IAuthUserStore create(Ref ref) {
    return authUserStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IAuthUserStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IAuthUserStore>(value),
    );
  }
}

String _$authUserStoreHash() => r'd2f63cd9300c4d8ab581c403ad2d3658528f9695';
