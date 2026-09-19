import 'package:mali_app/application/export/export_service.dart';
import 'package:mali_app/application/providers/auth_store_providers.dart';
import 'package:mali_app/application/providers/logging_providers.dart';
import 'package:mali_app/application/providers/repository_providers.dart';
import 'package:mali_app/data/export/csv_export_renderer.dart';
import 'package:mali_app/data/export/downloads_export_file_store.dart';
import 'package:mali_app/data/export/pdf_export_renderer.dart';
import 'package:mali_app/data/export/share_plus_file_share_service.dart';
import 'package:mali_app/domain/services/export_file_store.dart';
import 'package:mali_app/domain/services/export_renderer.dart';
import 'package:mali_app/domain/services/export_service.dart';
import 'package:mali_app/domain/services/file_share_service.dart';
import 'package:mali_app/domain/usecases/build_transaction_export_usecase.dart';
import 'package:mali_app/presentation/constants/system_categories.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'export_providers.g.dart';

@Riverpod(keepAlive: true)
BuildTransactionExportUseCase buildTransactionExportUseCase(Ref ref) {
  return BuildTransactionExportUseCase(
    transactionRepository: ref.watch(transactionRepositoryProvider),
    walletRepository: ref.watch(walletRepositoryProvider),
    categoryNameLookup: ref.watch(exportCategoryNameLookupProvider),
  );
}

/// Categories are not yet synced locally, so exports resolve names from the
/// system category list.
@Riverpod(keepAlive: true)
ExportCategoryNameLookup exportCategoryNameLookup(Ref ref) {
  return (categoryId) => SystemCategories.nameForOrNull(categoryId);
}

@Riverpod(keepAlive: true)
IExportRenderer pdfExportRenderer(Ref ref) {
  return const PdfExportRenderer();
}

@Riverpod(keepAlive: true)
IExportRenderer csvExportRenderer(Ref ref) {
  return const CsvExportRenderer();
}

@Riverpod(keepAlive: true)
IExportFileStore exportFileStore(Ref ref) {
  return const DownloadsExportFileStore();
}

@Riverpod(keepAlive: true)
IFileShareService fileShareService(Ref ref) {
  return const SharePlusFileShareService();
}

@Riverpod(keepAlive: true)
IExportService exportService(Ref ref) {
  return ExportService(
    buildTransactionExport: ref.watch(buildTransactionExportUseCaseProvider),
    pdfRenderer: ref.watch(pdfExportRendererProvider),
    csvRenderer: ref.watch(csvExportRendererProvider),
    fileStore: ref.watch(exportFileStoreProvider),
    authUserStore: ref.watch(authUserStoreProvider),
    logger: ref.watch(appLoggerProvider),
  );
}
