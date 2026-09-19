import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mali_app/presentation/widgets/sovereign/sovereign_bottom_nav.dart';

const _shellRoutePrefixes = ['/home', '/wallets', '/budgets', '/goals'];

bool isShellRoute(BuildContext context) {
  final path = GoRouter.maybeOf(context)?.state.uri.path;
  if (path == null) {
    return false;
  }
  return _shellRoutePrefixes.any(path.startsWith);
}

double shellBottomInset(BuildContext context) {
  if (!isShellRoute(context)) {
    return 0;
  }
  return SovereignBottomNav.contentInset(context);
}

EdgeInsets modalSheetPadding(
  BuildContext context, {
  double left = 24,
  double top = 16,
  double right = 24,
  double bottom = 24,
}) {
  final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
  return EdgeInsets.fromLTRB(
    left,
    top,
    right,
    bottom + keyboardInset + shellBottomInset(context),
  );
}
