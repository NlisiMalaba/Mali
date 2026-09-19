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
    if (location.startsWith('/wallets')) {
      return SovereignNavDestination.wallets;
    }
    if (location.startsWith('/budgets')) {
      return SovereignNavDestination.budgets;
    }
    if (location.startsWith('/goals')) {
      return SovereignNavDestination.goals;
    }
    return SovereignNavDestination.home;
  }

  void _onDestinationSelected(BuildContext context, SovereignNavDestination dest) {
    switch (dest) {
      case SovereignNavDestination.home:
        context.go('/home');
      case SovereignNavDestination.wallets:
        context.go('/wallets');
      case SovereignNavDestination.budgets:
        context.go('/budgets');
      case SovereignNavDestination.goals:
        context.go('/goals');
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final selected = _selectedDestination(location);

    return Scaffold(
      body: child,
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
