import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mali_app/application/providers/biometric_providers.dart';
import 'package:mali_app/application/providers/pin_lock_providers.dart';
import 'package:mali_app/application/providers/pin_lock_store_providers.dart';
import 'package:mali_app/application/providers/use_case_providers.dart';
import 'package:mali_app/domain/usecases/set_biometric_unlock_usecase.dart';
import 'package:mali_app/presentation/utils/biometric_labels.dart';
import 'package:mali_app/presentation/widgets/security/pin_entry_panel.dart';

class SecuritySettingsScreen extends ConsumerWidget {
  const SecuritySettingsScreen({super.key});

  static const Key screenKey = Key('security-settings-screen');

  Future<void> _disablePin(BuildContext context, WidgetRef ref) async {
    final pin = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * 0.75,
          child: PinEntryPanel(
            title: 'Enter current PIN',
            subtitle: 'Confirm to turn off app lock',
            onCompleted: (entered) async {
              Navigator.of(sheetContext).pop(entered);
              return null;
            },
          ),
        );
      },
    );

    if (pin == null || !context.mounted) {
      return;
    }

    final result = await ref.read(disablePinLockUseCaseProvider)(pin);
    if (!context.mounted) {
      return;
    }

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
      },
      (_) async {
        await ref.read(pinLockControllerProvider.notifier).onPinDisabled();
        if (!context.mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN lock turned off.')),
        );
      },
    );
  }

  Future<void> _setBiometricUnlock(
    BuildContext context,
    WidgetRef ref, {
    required bool enabled,
  }) async {
    final result = await ref.read(setBiometricUnlockUseCaseProvider)(
      SetBiometricUnlockParams(enabled: enabled),
    );

    if (!context.mounted) {
      return;
    }

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
      },
      (_) {
        ref
            .read(pinLockControllerProvider.notifier)
            .onBiometricEnabledChanged(enabled);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              enabled
                  ? 'Biometric unlock enabled.'
                  : 'Biometric unlock disabled.',
            ),
          ),
        );
      },
    );
  }

  Future<void> _enablePin(BuildContext context, WidgetRef ref) async {
    final created = await context.push<bool>('/settings/security/pin-setup');
    if (created != true || !context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PIN lock enabled.')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinLockAsync = ref.watch(pinLockControllerProvider);
    final capabilityAsync = ref.watch(biometricCapabilityProvider);

    return Scaffold(
      key: screenKey,
      appBar: AppBar(title: const Text('Security')),
      body: pinLockAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Could not load security: $error')),
        data: (pinLock) {
          return ListView(
            children: [
              SwitchListTile(
                key: const Key('pin-lock-switch'),
                title: const Text('PIN lock'),
                subtitle: const Text(
                  'Require a 4-digit PIN when opening Mali',
                ),
                value: pinLock.isEnabled,
                onChanged: (enabled) async {
                  if (enabled) {
                    await _enablePin(context, ref);
                  } else {
                    await _disablePin(context, ref);
                  }
                },
              ),
              if (pinLock.isEnabled)
                capabilityAsync.when(
                  loading: () => const ListTile(
                    leading: Icon(Icons.fingerprint),
                    title: Text('Biometric unlock'),
                    trailing: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  error: (error, stackTrace) => const SizedBox.shrink(),
                  data: (capability) {
                    if (!capability.isAvailable) {
                      return const SizedBox.shrink();
                    }

                    return SwitchListTile(
                      key: const Key('biometric-unlock-switch'),
                      secondary: Icon(
                        capability.hasFace
                            ? Icons.face_unlock_outlined
                            : Icons.fingerprint,
                      ),
                      title: Text(BiometricLabels.settingsTitle(capability)),
                      subtitle: Text(
                        BiometricLabels.settingsSubtitle(capability),
                      ),
                      value: pinLock.isBiometricEnabled,
                      onChanged: (enabled) =>
                          _setBiometricUnlock(context, ref, enabled: enabled),
                    );
                  },
                ),
              if (pinLock.isEnabled)
                ListTile(
                  leading: const Icon(Icons.pin_outlined),
                  title: const Text('Change PIN'),
                  subtitle: const Text('Set a new 4-digit PIN'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final verified = await showModalBottomSheet<bool>(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      builder: (sheetContext) {
                        return SizedBox(
                          height: MediaQuery.sizeOf(sheetContext).height * 0.75,
                          child: PinEntryPanel(
                            title: 'Enter current PIN',
                            subtitle: 'Then choose a new PIN',
                            onCompleted: (entered) async {
                              final valid = await ref
                                  .read(pinLockRepositoryProvider)
                                  .verifyPin(entered);
                              if (!valid) {
                                return 'Incorrect PIN.';
                              }
                              if (sheetContext.mounted) {
                                Navigator.of(sheetContext).pop(true);
                              }
                              return null;
                            },
                          ),
                        );
                      },
                    );

                    if (verified == true && context.mounted) {
                      final changed =
                          await context.push<bool>('/settings/security/pin-setup');
                      if (changed == true && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('PIN updated.')),
                        );
                      }
                    }
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}
