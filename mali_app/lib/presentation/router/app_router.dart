import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mali_app/application/providers/auth_provider.dart';
import 'package:mali_app/application/providers/pin_lock_providers.dart';
import 'package:mali_app/application/providers/wallet_providers.dart';
import 'package:mali_app/presentation/screens/security/pin_entry_screen.dart';
import 'package:mali_app/presentation/screens/security/pin_setup_screen.dart';
import 'package:mali_app/presentation/screens/settings/security_settings_screen.dart';
import 'package:mali_app/presentation/screens/budget/budgets_screen.dart';
import 'package:mali_app/presentation/screens/goal/goal_detail_screen.dart';
import 'package:mali_app/presentation/screens/goal/goal_priority_screen.dart';
import 'package:mali_app/presentation/screens/goal/goals_screen.dart';
import 'package:mali_app/presentation/screens/analytics/analytics_screen.dart';
import 'package:mali_app/presentation/screens/analytics/category_drilldown_screen.dart';
import 'package:mali_app/presentation/screens/auth/login_screen.dart';
import 'package:mali_app/presentation/screens/auth/register_screen.dart';
import 'package:mali_app/presentation/screens/home/home_screen.dart';
import 'package:mali_app/presentation/screens/placeholder_screen.dart';
import 'package:mali_app/presentation/screens/settings/exchange_rates_settings_screen.dart';
import 'package:mali_app/presentation/screens/settings/export_screen.dart';
import 'package:mali_app/presentation/screens/settings/settings_screen.dart';
import 'package:mali_app/presentation/screens/splash_screen.dart';
import 'package:mali_app/presentation/screens/transaction/add_transaction_screen.dart';
import 'package:mali_app/presentation/screens/transaction/transaction_list_screen.dart';
import 'package:mali_app/presentation/screens/wallet/wallet_setup_screen.dart';
import 'package:mali_app/presentation/screens/wallet/wallets_screen.dart';
import 'package:mali_app/presentation/widgets/app_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final routerRefreshListenable = ValueNotifier<int>(0);
  ref.listen(authProvider, (previous, next) {
    if (previous != next) {
      routerRefreshListenable.value++;
    }
  });
  ref.listen(activeWalletsProvider, (previous, next) {
    if (previous != next) {
      routerRefreshListenable.value++;
    }
  });
  ref.listen(pinLockControllerProvider, (previous, next) {
    if (previous != next) {
      routerRefreshListenable.value++;
    }
  });
  ref.onDispose(routerRefreshListenable.dispose);

  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/wallet-setup',
        builder: (context, state) => const WalletSetupScreen(),
      ),
      GoRoute(
        path: '/lock/pin',
        builder: (context, state) => const PinEntryScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/transactions',
            builder: (context, state) => const TransactionListScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/add-transaction',
        builder: (context, state) => const AddTransactionScreen(),
      ),
      GoRoute(
        path: '/budgets',
        builder: (context, state) => const BudgetsScreen(),
      ),
      GoRoute(
        path: '/wallets',
        builder: (context, state) => const WalletsScreen(),
        routes: [
          GoRoute(
            path: ':walletId',
            builder: (context, state) {
              final walletId = state.pathParameters['walletId'] ?? '';
              return TransactionListScreen(walletId: walletId);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/goals',
        builder: (context, state) => const GoalsScreen(),
        routes: [
          GoRoute(
            path: 'priority',
            builder: (context, state) => const GoalPriorityScreen(),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final goalId = state.pathParameters['id'] ?? '';
              return GoalDetailScreen(goalId: goalId);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/analytics',
        builder: (context, state) => AnalyticsScreen(
          initialTab: AnalyticsScreen.tabFromQuery(
            state.uri.queryParameters[AnalyticsScreen.tabQuery],
          ),
        ),
        routes: [
          GoRoute(
            path: 'categories/:categoryId',
            builder: (context, state) {
              final now = DateTime.now();
              final categoryId = state.pathParameters['categoryId'] ?? '';
              final year = int.tryParse(
                    state.uri.queryParameters['year'] ?? '',
                  ) ??
                  now.year;
              final month = int.tryParse(
                    state.uri.queryParameters['month'] ?? '',
                  ) ??
                  now.month;
              return CategoryDrilldownScreen(
                categoryId: categoryId,
                year: year,
                month: month,
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'exchange-rates',
            builder: (context, state) =>
                const ExchangeRatesSettingsScreen(),
          ),
          GoRoute(
            path: 'export',
            builder: (context, state) => const ExportScreen(),
          ),
          GoRoute(
            path: 'notifications',
            builder: (context, state) => const PlaceholderScreen(
              title: 'Notifications',
            ),
          ),
          GoRoute(
            path: 'security',
            builder: (context, state) => const SecuritySettingsScreen(),
            routes: [
              GoRoute(
                path: 'pin-setup',
                builder: (context, state) => const PinSetupScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final location = state.uri.path;
      final isAuthPage =
          location == '/auth/login' || location == '/auth/register';
      final isWalletSetup = location == '/wallet-setup';
      final isLockRoute = location.startsWith('/lock');

      if (auth.isLoading) {
        if (location != '/' && !isAuthPage) {
          return '/';
        }
        return null;
      }

      if (auth.hasError) {
        if (!isAuthPage && location != '/') {
          return '/auth/login';
        }
        return null;
      }

      final user = auth.value;
      final isAuthenticated = user != null;

      if (!isAuthenticated && !isAuthPage && location != '/') {
        return '/auth/login';
      }

      if (isAuthenticated) {
        final needsSetup = ref.read(needsWalletSetupProvider);

        if (isAuthPage) {
          return needsSetup ? '/wallet-setup' : '/home';
        }

        if (needsSetup && !isWalletSetup && location != '/') {
          return '/wallet-setup';
        }

        if (!needsSetup && isWalletSetup) {
          return '/home';
        }

        final pinLock = ref.read(pinLockControllerProvider).value;
        if (pinLock != null &&
            pinLock.needsUnlock &&
            !isLockRoute &&
            !isWalletSetup &&
            location != '/') {
          return '/lock/pin';
        }

        if (pinLock != null && !pinLock.needsUnlock && location == '/lock/pin') {
          return '/home';
        }
      }

      return null;
    },
    refreshListenable: routerRefreshListenable,
  );
});
