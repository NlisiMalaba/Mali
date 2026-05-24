// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pin_lock_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PinLockController)
final pinLockControllerProvider = PinLockControllerProvider._();

final class PinLockControllerProvider
    extends $AsyncNotifierProvider<PinLockController, PinLockState> {
  PinLockControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pinLockControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pinLockControllerHash();

  @$internal
  @override
  PinLockController create() => PinLockController();
}

String _$pinLockControllerHash() => r'dacf263f500f8647db57e303208aef7374e3e14c';

abstract class _$PinLockController extends $AsyncNotifier<PinLockState> {
  FutureOr<PinLockState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<PinLockState>, PinLockState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<PinLockState>, PinLockState>,
              AsyncValue<PinLockState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(pinLockNeedsUnlock)
final pinLockNeedsUnlockProvider = PinLockNeedsUnlockProvider._();

final class PinLockNeedsUnlockProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  PinLockNeedsUnlockProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pinLockNeedsUnlockProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pinLockNeedsUnlockHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return pinLockNeedsUnlock(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$pinLockNeedsUnlockHash() =>
    r'e6d9bc4368c0d1e081f5a9bb182688af457b498f';
