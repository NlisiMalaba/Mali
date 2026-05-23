import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mali_app/core/error/failure.dart';
import 'package:mali_app/data/sync/last_sync_store.dart';
import 'package:mali_app/data/sync/sync_queue_manager.dart';
import 'package:mali_app/domain/usecases/sync_usecase.dart';
import 'package:workmanager/workmanager.dart';

const String backgroundSyncTaskName = 'maliBackgroundSync';
const String backgroundSyncUniqueName = 'mali-periodic-sync';

class BackgroundSyncService {
  BackgroundSyncService({
    required SyncUseCase syncUseCase,
    required SyncQueueManager syncQueueManager,
    required LastSyncStore lastSyncStore,
    Connectivity? connectivity,
  })  : _syncUseCase = syncUseCase,
        _syncQueueManager = syncQueueManager,
        _lastSyncStore = lastSyncStore,
        _connectivity = connectivity ?? Connectivity();

  final SyncUseCase _syncUseCase;
  final SyncQueueManager _syncQueueManager;
  final LastSyncStore _lastSyncStore;
  final Connectivity _connectivity;

  Future<void> registerPeriodicSync() {
    return Workmanager().registerPeriodicTask(
      backgroundSyncUniqueName,
      backgroundSyncTaskName,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  }

  Future<BackgroundSyncResult> runSyncIfOnline() async {
    if (!await _isOnline()) {
      return BackgroundSyncResult.skippedOffline();
    }

    await _syncQueueManager.processPending();

    final since = await _lastSyncStore.readSince();
    final result = await _syncUseCase(since: since);

    if (result.isLeft()) {
      final failure = result.swap().getOrElse(
        (_) => const NetworkFailure(message: 'Sync failed.'),
      );
      return BackgroundSyncResult.failed(failure.message);
    }

    final syncResult = result.getOrElse((_) => throw StateError('Expected sync result.'));
    await _lastSyncStore.writeSince(syncResult.syncCompletedAt);
    return BackgroundSyncResult.succeeded(syncResult);
  }

  Future<bool> _isOnline() async {
    final statuses = await _connectivity.checkConnectivity();
    return statuses.any((status) => status != ConnectivityResult.none);
  }
}

class BackgroundSyncResult {
  const BackgroundSyncResult._({
    required this.status,
    this.syncResult,
    this.message,
  });

  factory BackgroundSyncResult.skippedOffline() {
    return const BackgroundSyncResult._(status: BackgroundSyncStatus.skippedOffline);
  }

  factory BackgroundSyncResult.succeeded(SyncResult syncResult) {
    return BackgroundSyncResult._(
      status: BackgroundSyncStatus.succeeded,
      syncResult: syncResult,
    );
  }

  factory BackgroundSyncResult.failed(String message) {
    return BackgroundSyncResult._(
      status: BackgroundSyncStatus.failed,
      message: message,
    );
  }

  final BackgroundSyncStatus status;
  final SyncResult? syncResult;
  final String? message;
}

enum BackgroundSyncStatus {
  skippedOffline,
  succeeded,
  failed,
}
