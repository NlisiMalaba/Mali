import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mali_app/application/providers/auth_provider.dart';
import 'package:mali_app/presentation/widgets/mali_logo.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  static const Duration minimumDisplayDuration = Duration(milliseconds: 1500);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _minimumDurationElapsed = false;
  Timer? _displayTimer;

  @override
  void initState() {
    super.initState();
    _displayTimer = Timer(SplashScreen.minimumDisplayDuration, () {
      if (!mounted) return;
      setState(() => _minimumDurationElapsed = true);
      _tryNavigate();
    });
  }

  @override
  void dispose() {
    _displayTimer?.cancel();
    super.dispose();
  }

  void _tryNavigate() {
    if (!_minimumDurationElapsed || !mounted) {
      return;
    }

    final auth = ref.read(authProvider);
    if (auth.isLoading) {
      return;
    }

    final isAuthenticated = auth.hasValue && auth.value != null;
    context.go(isAuthenticated ? '/home' : '/auth/login');
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (previous, next) {
      if (!next.isLoading) {
        _tryNavigate();
      }
    });

    return const Scaffold(
      body: Center(
        child: MaliLogo(),
      ),
    );
  }
}
