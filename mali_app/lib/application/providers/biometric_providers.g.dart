// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'biometric_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(biometricAuthenticator)
final biometricAuthenticatorProvider = BiometricAuthenticatorProvider._();

final class BiometricAuthenticatorProvider
    extends
        $FunctionalProvider<
          IBiometricAuthenticator,
          IBiometricAuthenticator,
          IBiometricAuthenticator
        >
    with $Provider<IBiometricAuthenticator> {
  BiometricAuthenticatorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'biometricAuthenticatorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$biometricAuthenticatorHash();

  @$internal
  @override
  $ProviderElement<IBiometricAuthenticator> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  IBiometricAuthenticator create(Ref ref) {
    return biometricAuthenticator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IBiometricAuthenticator value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IBiometricAuthenticator>(value),
    );
  }
}

String _$biometricAuthenticatorHash() =>
    r'55a944a5fcf1293d77f55c4175874dae715d73e6';

@ProviderFor(biometricCapability)
final biometricCapabilityProvider = BiometricCapabilityProvider._();

final class BiometricCapabilityProvider
    extends
        $FunctionalProvider<
          AsyncValue<BiometricCapability>,
          BiometricCapability,
          FutureOr<BiometricCapability>
        >
    with
        $FutureModifier<BiometricCapability>,
        $FutureProvider<BiometricCapability> {
  BiometricCapabilityProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'biometricCapabilityProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$biometricCapabilityHash();

  @$internal
  @override
  $FutureProviderElement<BiometricCapability> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<BiometricCapability> create(Ref ref) {
    return biometricCapability(ref);
  }
}

String _$biometricCapabilityHash() =>
    r'3edf6507e0c98f5aad45a9add26d0ec39408ceef';
