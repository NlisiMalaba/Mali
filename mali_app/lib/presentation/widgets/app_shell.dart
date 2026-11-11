import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mali_app/presentation/widgets/sovereign/sovereign_bottom_nav.dart';
import 'package:mali_app/presentation/widgets/transaction/add_transaction_sheet.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    required this.child,
    super.key,
  });

  final Widget child;

  SovereignNavDestination _selectedDestination(String location) {
    if (location.startsWith('/analytics') || location.startsWith('/insights')) {
      return SovereignNavDestination.insights;
    }
    if (location.startsWith('/goals')) {
      return SovereignNavDestination.goals;
    }
    if (location.startsWith('/settings') ||
        location.startsWith('/wallets') ||
        location.startsWith('/budgets')) {
      return SovereignNavDestination.settings;
    }
    return SovereignNavDestination.home;
  }

  void _onDestinationSelected(
    BuildContext context,
    SovereignNavDestination dest,
  ) {
    switch (dest) {
      case SovereignNavDestination.home:
        context.go('/home');
      case SovereignNavDestination.insights:
        context.go('/analytics');
      case SovereignNavDestination.goals:
        context.go('/goals');
      case SovereignNavDestination.settings:
        context.go('/settings');
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final selected = _selectedDestination(location);

    return Scaffold(
      body: Padding(
        padding: EdgeInsets.only(
          bottom: SovereignBottomNav.contentInset(context),
        ),
        child: child,
      ),
      extendBody: true,
      bottomNavigationBar: SovereignBottomNav(
        selected: selected,
        onDestinationSelected: (dest) =>
            _onDestinationSelected(context, dest),
        onAddPressed: () => AddTransactionSheet.show(context),
      ),
    );
  }
}
