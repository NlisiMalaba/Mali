// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(notificationService)
final notificationServiceProvider = NotificationServiceProvider._();

final class NotificationServiceProvider
    extends
        $FunctionalProvider<
          INotificationService,
          INotificationService,
          INotificationService
        >
    with $Provider<INotificationService> {
  NotificationServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationServiceHash();

  @$internal
  @override
  $ProviderElement<INotificationService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  INotificationService create(Ref ref) {
    return notificationService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(INotificationService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<INotificationService>(value),
    );
  }
}

String _$notificationServiceHash() =>
    r'e3b4658d7dbc7bfcff8239fd6cc2f8d3dc43479c';
