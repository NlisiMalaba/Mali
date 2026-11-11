import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mali_app/application/providers/auth_provider.dart';
import 'package:mali_app/application/providers/biometric_providers.dart';
import 'package:mali_app/application/providers/pin_lock_providers.dart';
import 'package:mali_app/core/constants/pin_lock_constants.dart';
import 'package:mali_app/domain/repositories/biometric_authenticator.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/widgets/common/fade_slide_in.dart';
import 'package:mali_app/presentation/widgets/common/pressable_scale.dart';
import 'package:mali_app/presentation/widgets/security/pin_dots.dart';
import 'package:mali_app/presentation/widgets/security/pin_keypad.dart';

class PinEntryScreen extends ConsumerStatefulWidget {
  const PinEntryScreen({super.key});

  static const Key screenKey = Key('pin-entry-screen');

  @override
  ConsumerState<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends ConsumerState<PinEntryScreen>
    with SingleTickerProviderStateMixin {
  final _buffer = StringBuffer();
  bool _isBiometricLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _biometricError;
  late final AnimationController _shake;

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometricUnlock());
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  String _firstName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    return trimmed.split(RegExp(r'\s+')).first;
  }

  Future<void> _navigateAfterUnlock() async {
    if (!mounted) {
      return;
    }
    final router = GoRouter.maybeOf(context);
    if (router == null) {
      return;
    }
    final location = GoRouterState.of(context).uri.path;
    if (location == '/lock/pin') {
      router.go('/home');
    }
  }

  Future<void> _tryBiometricUnlock() async {
    final pinLock = ref.read(pinLockControllerProvider).value;
    if (pinLock == null || !pinLock.isBiometricEnabled) {
      return;
    }
    await _authenticateWithBiometric();
  }

  Future<void> _authenticateWithBiometric() async {
    if (_isBiometricLoading || _isSubmitting) {
      return;
    }

    setState(() {
      _isBiometricLoading = true;
      _biometricError = null;
      _errorMessage = null;
    });

    final error =
        await ref.read(pinLockControllerProvider.notifier).unlockWithBiometric();

    if (!mounted) {
      return;
    }

    setState(() => _isBiometricLoading = false);

    if (error == null) {
      final pinLock = ref.read(pinLockControllerProvider).value;
      if (pinLock != null && !pinLock.needsUnlock) {
        await _navigateAfterUnlock();
      }
      return;
    }

    setState(() => _biometricError = error);
  }

  void _onDigit(String digit) {
    if (_isSubmitting || _buffer.length >= PinLockConstants.pinLength) {
      return;
    }

    setState(() {
      _errorMessage = null;
      _biometricError = null;
      _buffer.write(digit);
    });

    if (_buffer.length == PinLockConstants.pinLength) {
      _submit();
    }
  }

  void _onBackspace() {
    if (_isSubmitting || _buffer.isEmpty) {
      return;
    }

    setState(() {
      _errorMessage = null;
      final value = _buffer.toString();
      _buffer
        ..clear()
        ..write(value.substring(0, value.length - 1));
    });
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);

    final pin = _buffer.toString();
    final error =
        await ref.read(pinLockControllerProvider.notifier).unlock(pin);

    if (!mounted) {
      return;
    }

    if (error == null) {
      await _navigateAfterUnlock();
      return;
    }

    setState(() {
      _isSubmitting = false;
      _buffer.clear();
      _errorMessage = error;
    });
    if (!MediaQuery.disableAnimationsOf(context)) {
      await _shake.forward(from: 0);
    }
  }

  Future<void> _onForgotPin() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Forgot PIN?'),
          content: const Text(
            'Sign out, then sign back in and set a new PIN from Security.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const Key('pin-forgot-sign-out'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Sign out'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }
    await ref.read(authProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context) {
    final pinLock = ref.watch(pinLockControllerProvider).value;
    final capabilityAsync = ref.watch(biometricCapabilityProvider);
    final showBiometric = pinLock?.isBiometricEnabled == true;
    final userName = ref.watch(authProvider).maybeWhen(
          data: (user) => user?.name ?? '',
          orElse: () => '',
        );
    final firstName = _firstName(userName);
    final greeting = firstName.isEmpty ? 'Hi' : 'Hi $firstName';

    return PopScope(
      canPop: false,
      child: Scaffold(
        key: PinEntryScreen.screenKey,
        backgroundColor: AppColors.navy,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 24, 32, 16),
            child: Column(
              children: [
                FadeSlideIn(
                  index: 0,
                  child: _LockHero(
                    greeting: greeting,
                  ),
                ),
                const SizedBox(height: 28),
                FadeSlideIn(
                  index: 1,
                  child: AnimatedBuilder(
                    animation: _shake,
                    builder: (context, child) {
                      final dx = math.sin(_shake.value * math.pi * 4) *
                          10 *
                          (1 - _shake.value);
                      return Transform.translate(
                        offset: Offset(dx, 0),
                        child: child,
                      );
                    },
                    child: PinDots(
                      enteredLength: _buffer.length,
                      chrome: PinChrome.dark,
                      hasError: _errorMessage != null,
                    ),
                  ),
                ),
                if (_errorMessage != null || _biometricError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage ?? _biometricError!,
                    key: const Key('pin-entry-error'),
                    style: const TextStyle(
                      color: Color(0xFFFFB4A8),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const Spacer(),
                FadeSlideIn(
                  index: 2,
                  offsetY: 28,
                  child: PinKeypad(
                    chrome: PinChrome.dark,
                    enabled: !_isSubmitting,
                    onDigit: _onDigit,
                    onBackspace: _onBackspace,
                  ),
                ),
                const SizedBox(height: 10),
                FadeSlideIn(
                  index: 3,
                  child: _FooterActions(
                    showBiometric: showBiometric,
                    capabilityAsync: capabilityAsync,
                    isBiometricLoading: _isBiometricLoading,
                    onForgotPin: _onForgotPin,
                    onBiometric: _authenticateWithBiometric,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LockHero extends StatelessWidget {
  const _LockHero({required this.greeting});

  final String greeting;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.navyRaised,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.navyBorder),
          ),
          child: const Icon(
            Icons.lock_outline_rounded,
            color: AppColors.silver,
            size: 30,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          greeting,
          key: const Key('pin-entry-greeting'),
          style: GoogleFonts.spaceGrotesk(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AppColors.onPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        const Text(
          'Enter your PIN to open Master of Coin',
          style: TextStyle(
            color: AppColors.onNavyMuted,
            fontSize: 14.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _FooterActions extends StatelessWidget {
  const _FooterActions({
    required this.showBiometric,
    required this.capabilityAsync,
    required this.isBiometricLoading,
    required this.onForgotPin,
    required this.onBiometric,
  });

  final bool showBiometric;
  final AsyncValue<BiometricCapability> capabilityAsync;
  final bool isBiometricLoading;
  final VoidCallback onForgotPin;
  final VoidCallback onBiometric;

  @override
  Widget build(BuildContext context) {
    final biometric = showBiometric
        ? capabilityAsync.maybeWhen(
            data: (capability) => capability.isAvailable ? capability : null,
            orElse: () => null,
          )
        : null;

    return SizedBox(
      height: 56,
      child: Row(
        children: [
          PressableScale(
            onTap: onForgotPin,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Forgot PIN?',
                key: Key('pin-forgot-link'),
                style: TextStyle(
                  color: AppColors.onNavyLink,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const Spacer(),
          if (biometric != null)
            PressableScale(
              onTap: isBiometricLoading ? null : onBiometric,
              child: Container(
                key: const Key('biometric-unlock-button'),
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.navyRaised,
                  shape: BoxShape.circle,
                ),
                child: isBiometricLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: AppColors.silver,
                        ),
                      )
                    : Icon(
                        biometric.hasFace
                            ? Icons.face_unlock_outlined
                            : Icons.fingerprint,
                        color: AppColors.silver,
                        size: 26,
                      ),
              ),
            ),
        ],
      ),
    );
  }
}
