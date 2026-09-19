// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'logging_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(appLogger)
final appLoggerProvider = AppLoggerProvider._();

final class AppLoggerProvider
    extends $FunctionalProvider<IAppLogger, IAppLogger, IAppLogger>
    with $Provider<IAppLogger> {
  AppLoggerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appLoggerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appLoggerHash();

  @$internal
  @override
  $ProviderElement<IAppLogger> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  IAppLogger create(Ref ref) {
    return appLogger(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IAppLogger value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IAppLogger>(value),
    );
  }
}

String _$appLoggerHash() => r'5052e5d7a2b57e24e325489ed052dc49b859db79';
