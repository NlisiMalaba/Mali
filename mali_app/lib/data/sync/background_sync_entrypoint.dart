import 'package:flutter/widgets.dart';
import 'package:mali_app/data/sync/background_sync_service.dart';
import 'package:mali_app/data/sync/sync_bootstrap.dart';
import 'package:workmanager/workmanager.dart';

@pragma('vm:entry-point')
void backgroundSyncDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName != backgroundSyncTaskName) {
      return false;
    }

    WidgetsFlutterBinding.ensureInitialized();

    final bootstrap = await SyncBootstrap.createForBackgroundIsolate();
    try {
      final result = await bootstrap.backgroundSyncService.runSyncIfOnline();
      return result.status == BackgroundSyncStatus.succeeded ||
          result.status == BackgroundSyncStatus.skippedOffline;
    } finally {
      await bootstrap.database.close();
    }
  });
}
