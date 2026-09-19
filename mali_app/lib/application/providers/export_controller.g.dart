// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'export_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Runs an export and then offers the saved file to the share sheet.
///
/// The state holds the most recent successful export so the UI can report
/// where the file landed.

@ProviderFor(ExportController)
final exportControllerProvider = ExportControllerProvider._();

/// Runs an export and then offers the saved file to the share sheet.
///
/// The state holds the most recent successful export so the UI can report
/// where the file landed.
final class ExportControllerProvider
    extends $AsyncNotifierProvider<ExportController, ExportedFile?> {
  /// Runs an export and then offers the saved file to the share sheet.
  ///
  /// The state holds the most recent successful export so the UI can report
  /// where the file landed.
  ExportControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exportControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exportControllerHash();

  @$internal
  @override
  ExportController create() => ExportController();
}

String _$exportControllerHash() => r'0c0fe6b6d709391b89e5eb3d4479ece08e5e7937';

/// Runs an export and then offers the saved file to the share sheet.
///
/// The state holds the most recent successful export so the UI can report
/// where the file landed.

abstract class _$ExportController extends $AsyncNotifier<ExportedFile?> {
  FutureOr<ExportedFile?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<ExportedFile?>, ExportedFile?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ExportedFile?>, ExportedFile?>,
              AsyncValue<ExportedFile?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
