import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mali_app/presentation/router/app_router.dart';
import 'package:mali_app/presentation/theme/app_theme.dart';

void main() {
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
