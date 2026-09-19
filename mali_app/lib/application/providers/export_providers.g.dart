// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'export_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(buildTransactionExportUseCase)
final buildTransactionExportUseCaseProvider =
    BuildTransactionExportUseCaseProvider._();

final class BuildTransactionExportUseCaseProvider
    extends
        $FunctionalProvider<
          BuildTransactionExportUseCase,
          BuildTransactionExportUseCase,
          BuildTransactionExportUseCase
        >
    with $Provider<BuildTransactionExportUseCase> {
  BuildTransactionExportUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'buildTransactionExportUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$buildTransactionExportUseCaseHash();

  @$internal
  @override
  $ProviderElement<BuildTransactionExportUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BuildTransactionExportUseCase create(Ref ref) {
    return buildTransactionExportUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BuildTransactionExportUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BuildTransactionExportUseCase>(
        value,
      ),
    );
  }
}

String _$buildTransactionExportUseCaseHash() =>
    r'804d5c2d8c809ef3491217695cc418b587cac0d3';

/// Categories are not yet synced locally, so exports resolve names from the
/// system category list.

@ProviderFor(exportCategoryNameLookup)
final exportCategoryNameLookupProvider = ExportCategoryNameLookupProvider._();

/// Categories are not yet synced locally, so exports resolve names from the
/// system category list.

final class ExportCategoryNameLookupProvider
    extends
        $FunctionalProvider<
          ExportCategoryNameLookup,
          ExportCategoryNameLookup,
          ExportCategoryNameLookup
        >
    with $Provider<ExportCategoryNameLookup> {
  /// Categories are not yet synced locally, so exports resolve names from the
  /// system category list.
  ExportCategoryNameLookupProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exportCategoryNameLookupProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exportCategoryNameLookupHash();

  @$internal
  @override
  $ProviderElement<ExportCategoryNameLookup> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ExportCategoryNameLookup create(Ref ref) {
    return exportCategoryNameLookup(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ExportCategoryNameLookup value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ExportCategoryNameLookup>(value),
    );
  }
}

String _$exportCategoryNameLookupHash() =>
    r'ea0da8de678b95b086a3d633aa35ca2eb102e69c';

@ProviderFor(pdfExportRenderer)
final pdfExportRendererProvider = PdfExportRendererProvider._();

final class PdfExportRendererProvider
    extends
        $FunctionalProvider<IExportRenderer, IExportRenderer, IExportRenderer>
    with $Provider<IExportRenderer> {
  PdfExportRendererProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pdfExportRendererProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pdfExportRendererHash();

  @$internal
  @override
  $ProviderElement<IExportRenderer> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  IExportRenderer create(Ref ref) {
    return pdfExportRenderer(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IExportRenderer value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IExportRenderer>(value),
    );
  }
}

String _$pdfExportRendererHash() => r'f9f3caaaee21d973f262ab2bfe18b702ed26ec21';

@ProviderFor(csvExportRenderer)
final csvExportRendererProvider = CsvExportRendererProvider._();

final class CsvExportRendererProvider
    extends
        $FunctionalProvider<IExportRenderer, IExportRenderer, IExportRenderer>
    with $Provider<IExportRenderer> {
  CsvExportRendererProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'csvExportRendererProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$csvExportRendererHash();

  @$internal
  @override
  $ProviderElement<IExportRenderer> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  IExportRenderer create(Ref ref) {
    return csvExportRenderer(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IExportRenderer value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IExportRenderer>(value),
    );
  }
}

String _$csvExportRendererHash() => r'073dccf99136174e49557a797e75765dd1c09948';

@ProviderFor(exportFileStore)
final exportFileStoreProvider = ExportFileStoreProvider._();

final class ExportFileStoreProvider
    extends
        $FunctionalProvider<
          IExportFileStore,
          IExportFileStore,
          IExportFileStore
        >
    with $Provider<IExportFileStore> {
  ExportFileStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exportFileStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exportFileStoreHash();

  @$internal
  @override
  $ProviderElement<IExportFileStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  IExportFileStore create(Ref ref) {
    return exportFileStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IExportFileStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IExportFileStore>(value),
    );
  }
}

String _$exportFileStoreHash() => r'68b295297633bdb52a9023cbffa5cd0952a5195a';

@ProviderFor(fileShareService)
final fileShareServiceProvider = FileShareServiceProvider._();

final class FileShareServiceProvider
    extends
        $FunctionalProvider<
          IFileShareService,
          IFileShareService,
          IFileShareService
        >
    with $Provider<IFileShareService> {
  FileShareServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fileShareServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fileShareServiceHash();

  @$internal
  @override
  $ProviderElement<IFileShareService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  IFileShareService create(Ref ref) {
    return fileShareService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IFileShareService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IFileShareService>(value),
    );
  }
}

String _$fileShareServiceHash() => r'278df60951781877a58018043a1467cb501909b4';

@ProviderFor(exportService)
final exportServiceProvider = ExportServiceProvider._();

final class ExportServiceProvider
    extends $FunctionalProvider<IExportService, IExportService, IExportService>
    with $Provider<IExportService> {
  ExportServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exportServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exportServiceHash();

  @$internal
  @override
  $ProviderElement<IExportService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  IExportService create(Ref ref) {
    return exportService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IExportService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IExportService>(value),
    );
  }
}

String _$exportServiceHash() => r'9ea2673c86d7006468eba8d45df3d254c6941ace';
