import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mali_app/application/providers/auth_provider.dart';
import 'package:mali_app/application/providers/wallet_providers.dart';
import 'package:mali_app/presentation/screens/auth/login_screen.dart';
import 'package:mali_app/presentation/screens/auth/register_screen.dart';
import 'package:mali_app/presentation/screens/placeholder_screen.dart';
import 'package:mali_app/presentation/screens/splash_screen.dart';
import 'package:mali_app/presentation/screens/transaction/add_transaction_screen.dart';
import 'package:mali_app/presentation/screens/wallet/wallet_setup_screen.dart';
import 'package:mali_app/presentation/screens/wallet/wallet_transactions_screen.dart';
import 'package:mali_app/presentation/screens/wallet/wallets_screen.dart';

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
        path: '/home',
        builder: (context, state) => const PlaceholderScreen(title: 'Home'),
      ),
      GoRoute(
        path: '/add-transaction',
        builder: (context, state) => const AddTransactionScreen(),
      ),
      GoRoute(
        path: '/wallets',
        builder: (context, state) => const WalletsScreen(),
        routes: [
          GoRoute(
            path: ':walletId',
            builder: (context, state) {
              final walletId = state.pathParameters['walletId'] ?? '';
              return WalletTransactionsScreen(walletId: walletId);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/goals',
        builder: (context, state) => const PlaceholderScreen(title: 'Goals'),
      ),
      GoRoute(
        path: '/goals/:id',
        builder: (context, state) {
          final goalId = state.pathParameters['id'] ?? 'unknown';
          return PlaceholderScreen(title: 'Goal $goalId');
        },
      ),
      GoRoute(
        path: '/analytics',
        builder: (context, state) =>
            const PlaceholderScreen(title: 'Analytics'),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const PlaceholderScreen(title: 'Settings'),
      ),
    ],
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final location = state.uri.path;
      final isAuthPage =
          location == '/auth/login' || location == '/auth/register';
      final isWalletSetup = location == '/wallet-setup';

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
      }

      return null;
    },
    refreshListenable: routerRefreshListenable,
  );
});
