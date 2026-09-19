import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mali_app/application/providers/auth_session_listener_provider.dart';
import 'package:mali_app/application/providers/budget_alert_handler_provider.dart';
import 'package:mali_app/application/providers/connectivity_sync_listener_provider.dart';
import 'package:mali_app/application/providers/pin_lock_lifecycle_listener_provider.dart';
import 'package:mali_app/application/providers/pin_lock_providers.dart';
import 'package:mali_app/application/providers/reminder_providers.dart';
import 'package:mali_app/application/providers/sync_providers.dart';
import 'package:mali_app/application/providers/digest_providers.dart';
import 'package:mali_app/core/notifications/local_notification_service.dart';
import 'package:mali_app/data/background/background_task_entrypoint.dart';
import 'package:mali_app/presentation/router/app_router.dart';
import 'package:mali_app/presentation/theme/app_theme.dart';
import 'package:workmanager/workmanager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Workmanager().initialize(backgroundTaskDispatcher);

  await LocalNotificationService.instance.initialize();

  final container = ProviderContainer();
  final bootstrap = container.read(syncBootstrapProvider);
  await bootstrap.backgroundSyncService.registerPeriodicSync();
  await container.read(digestNotificationServiceProvider).registerWeeklyDigest();
  await container
      .read(contributionReminderServiceProvider)
      .scheduleNextReminder();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MaliApp(),
    ),
  );
}

class MaliApp extends ConsumerWidget {
  const MaliApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(authSessionListenerProvider);
    ref.watch(budgetAlertHandlerProvider);
    ref.watch(connectivitySyncListenerProvider);
    ref.watch(pinLockLifecycleListenerProvider);
    ref.watch(pinLockControllerProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Mali',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
