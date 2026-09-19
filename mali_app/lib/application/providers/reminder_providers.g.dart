// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reminder_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(contributionReminderService)
final contributionReminderServiceProvider =
    ContributionReminderServiceProvider._();

final class ContributionReminderServiceProvider
    extends
        $FunctionalProvider<
          ContributionReminderService,
          ContributionReminderService,
          ContributionReminderService
        >
    with $Provider<ContributionReminderService> {
  ContributionReminderServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'contributionReminderServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$contributionReminderServiceHash();

  @$internal
  @override
  $ProviderElement<ContributionReminderService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ContributionReminderService create(Ref ref) {
    return contributionReminderService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ContributionReminderService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ContributionReminderService>(value),
    );
  }
}

String _$contributionReminderServiceHash() =>
    r'5967a433f0e6bf2522e850f45dbb89019e6d9193';
