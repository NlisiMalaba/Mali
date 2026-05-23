import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mali_app/data/sync/background_sync_entrypoint.dart';
import 'package:mali_app/data/sync/sync_bootstrap.dart';
import 'package:mali_app/presentation/router/app_router.dart';
import 'package:mali_app/presentation/theme/app_theme.dart';
import 'package:workmanager/workmanager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Workmanager().initialize(backgroundSyncDispatcher);

  final bootstrap = await SyncBootstrap.create();
  await bootstrap.backgroundSyncService.registerPeriodicSync();

  runApp(const ProviderScope(child: MaliApp()));
}

class MaliApp extends ConsumerWidget {
  const MaliApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
