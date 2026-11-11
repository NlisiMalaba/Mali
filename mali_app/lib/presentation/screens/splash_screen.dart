import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mali_app/application/providers/auth_provider.dart';
import 'package:mali_app/application/providers/wallet_providers.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/theme/app_typography.dart';
import 'package:mali_app/presentation/widgets/mali_logo.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  static const Duration minimumDisplayDuration = Duration(milliseconds: 1500);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  bool _minimumDurationElapsed = false;
  Timer? _displayTimer;

  static const Duration _entranceDuration = Duration(milliseconds: 1600);

  /// The wordmark fades in once most coins have landed.
  static const double _wordmarkStart = 0.65;
  static const Duration _rippleDuration = Duration(milliseconds: 2400);
  static const double _logoSize = 96;
  static const double _rippleMaxScale = 2.6;

  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: _entranceDuration,
  );
  late final AnimationController _ripple = AnimationController(
    vsync: this,
    duration: _rippleDuration,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _entrance.value = 1;
      _ripple.stop();
    } else if (!_entrance.isAnimating && _entrance.value == 0) {
      _entrance.forward();
      _ripple.repeat();
    }
  }

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
    _entrance.dispose();
    _ripple.dispose();
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
    if (!isAuthenticated) {
      context.go('/welcome');
      return;
    }

    final needsSetup = ref.read(needsWalletSetupProvider);
    context.go(needsSetup ? '/wallet-setup' : '/home');
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (previous, next) {
      if (!next.isLoading) {
        _tryNavigate();
      }
    });
    ref.listen(activeWalletsProvider, (previous, next) {
      if (next.hasValue) {
        _tryNavigate();
      }
    });

    final wordmarkOpacity = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(_wordmarkStart, 1, curve: Curves.easeOut),
    );

    return Scaffold(
      backgroundColor: AppColors.navy,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: _logoSize * _rippleMaxScale,
              height: _logoSize * _rippleMaxScale,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  _Ripple(animation: _ripple, offset: 0),
                  _Ripple(animation: _ripple, offset: 0.5),
                  const MaliLogo(
                    size: _logoSize,
                    showWordmark: false,
                    onDark: true,
                    animate: true,
                  ),
                ],
              ),
            ),
            FadeTransition(
              opacity: wordmarkOpacity,
              child: Text.rich(
                const TextSpan(
                  children: [
                    TextSpan(text: 'Master\n'),
                    TextSpan(
                      text: 'of ',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w500,
                        color: AppColors.navInactive,
                      ),
                    ),
                    TextSpan(text: 'Coin'),
                  ],
                ),
                textAlign: TextAlign.center,
                style: AppTypography.money(
                  fontSize: 36,
                  color: AppColors.onPrimary,
                ).copyWith(height: 1.05),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Expanding silver ring behind the logo; two offset copies make a pulse.
class _Ripple extends StatelessWidget {
  const _Ripple({required this.animation, required this.offset});

  final Animation<double> animation;
  final double offset;

  static const double _startScale = 0.8;
  static const double _endScale = 2.6;
  static const double _startOpacity = 0.6;
  static const double _ringSize = 96;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = (animation.value + offset) % 1;
        return Opacity(
          opacity: _startOpacity * (1 - t),
          child: Transform.scale(
            scale: _startScale + (_endScale - _startScale) * t,
            child: Container(
              width: _ringSize,
              height: _ringSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_ringSize * 0.31),
                border: Border.all(color: AppColors.silver, width: 2),
              ),
            ),
          ),
        );
      },
    );
  }
}
