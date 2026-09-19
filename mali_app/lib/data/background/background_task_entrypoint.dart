import 'package:flutter/widgets.dart';
import 'package:mali_app/application/digest/digest_notification_service.dart';
import 'package:mali_app/application/reminders/contribution_reminder_service.dart';
import 'package:mali_app/data/background/notification_bootstrap.dart';
import 'package:mali_app/data/sync/background_sync_service.dart';
import 'package:mali_app/data/sync/sync_bootstrap.dart';
import 'package:workmanager/workmanager.dart';

/// Single WorkManager entrypoint; the plugin allows only one dispatcher, so
/// every background task is routed from here.
@pragma('vm:entry-point')
void backgroundTaskDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();

    switch (taskName) {
      case backgroundSyncTaskName:
        return _runBackgroundSync();
      case weeklyDigestTaskName:
        return _runWeeklyDigest();
      case contributionReminderTaskName:
        return _runContributionReminder();
      default:
        return false;
    }
  });
}

Future<bool> _runBackgroundSync() async {
  final bootstrap = await SyncBootstrap.createForBackgroundIsolate();
  try {
    final result = await bootstrap.backgroundSyncService.runSyncIfOnline();
    return result.status == BackgroundSyncStatus.succeeded ||
        result.status == BackgroundSyncStatus.skippedOffline;
  } finally {
    await bootstrap.database.close();
  }
}

Future<bool> _runWeeklyDigest() async {
  final bootstrap = await NotificationBootstrap.createForBackgroundIsolate();
  try {
    final result = await bootstrap.digestNotificationService.deliverDigest();
    return result.isSuccess;
  } finally {
    await bootstrap.database.close();
  }
}

Future<bool> _runContributionReminder() async {
  final bootstrap = await NotificationBootstrap.createForBackgroundIsolate();
  try {
    final result =
        await bootstrap.contributionReminderService.runScheduledReminder();
    return result.isSuccess;
  } finally {
    await bootstrap.database.close();
  }
}
