import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mali_app/application/providers/biometric_providers.dart';
import 'package:mali_app/application/providers/pin_lock_providers.dart';
import 'package:mali_app/presentation/widgets/security/biometric_unlock_button.dart';
import 'package:mali_app/presentation/widgets/security/pin_entry_panel.dart';

class PinEntryScreen extends ConsumerStatefulWidget {
  const PinEntryScreen({super.key});

  static const Key screenKey = Key('pin-entry-screen');

  @override
  ConsumerState<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends ConsumerState<PinEntryScreen> {
  bool _isBiometricLoading = false;
  String? _biometricError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometricUnlock());
  }

  Future<void> _navigateAfterUnlock() async {
    if (!mounted) {
      return;
    }
    final location = GoRouterState.of(context).uri.path;
    if (location == '/lock/pin') {
      context.go('/home');
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
    if (_isBiometricLoading) {
      return;
    }

    setState(() {
      _isBiometricLoading = true;
      _biometricError = null;
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

  @override
  Widget build(BuildContext context) {
    final pinLock = ref.watch(pinLockControllerProvider).value;
    final capabilityAsync = ref.watch(biometricCapabilityProvider);
    final showBiometric = pinLock?.isBiometricEnabled == true;

    return PopScope(
      canPop: false,
      child: Scaffold(
        key: PinEntryScreen.screenKey,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PinEntryPanel(
                  title: 'Enter your PIN',
                  subtitle: showBiometric
                      ? 'Or use biometrics to unlock'
                      : 'Unlock Mali to continue',
                  onCompleted: (pin) async {
                    final error = await ref
                        .read(pinLockControllerProvider.notifier)
                        .unlock(pin);
                    if (error == null) {
                      await _navigateAfterUnlock();
                    }
                    return error;
                  },
                ),
              ),
              if (showBiometric)
                capabilityAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (error, stackTrace) => const SizedBox.shrink(),
                  data: (capability) {
                    if (!capability.isAvailable) {
                      return const SizedBox.shrink();
                    }

                    return Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: Column(
                        children: [
                          if (_biometricError != null) ...[
                            Text(
                              _biometricError!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                          ],
                          BiometricUnlockButton(
                            capability: capability,
                            isLoading: _isBiometricLoading,
                            onPressed: _authenticateWithBiometric,
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
