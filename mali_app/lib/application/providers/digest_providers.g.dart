// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'digest_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(digestNotificationService)
final digestNotificationServiceProvider = DigestNotificationServiceProvider._();

final class DigestNotificationServiceProvider
    extends
        $FunctionalProvider<
          DigestNotificationService,
          DigestNotificationService,
          DigestNotificationService
        >
    with $Provider<DigestNotificationService> {
  DigestNotificationServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'digestNotificationServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$digestNotificationServiceHash();

  @$internal
  @override
  $ProviderElement<DigestNotificationService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DigestNotificationService create(Ref ref) {
    return digestNotificationService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DigestNotificationService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DigestNotificationService>(value),
    );
  }
}

String _$digestNotificationServiceHash() =>
    r'35f45f86a89e86675bad8814515beb33acb9ee79';
