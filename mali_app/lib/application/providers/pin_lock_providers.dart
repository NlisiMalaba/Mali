import 'package:mali_app/application/providers/pin_lock_store_providers.dart';
import 'package:mali_app/application/providers/use_case_providers.dart';
import 'package:mali_app/domain/repositories/biometric_authenticator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pin_lock_providers.g.dart';

class PinLockState {
  const PinLockState({
    required this.isEnabled,
    required this.isUnlocked,
    required this.isBiometricEnabled,
  });

  final bool isEnabled;
  final bool isUnlocked;
  final bool isBiometricEnabled;

  bool get needsUnlock => isEnabled && !isUnlocked;

  PinLockState copyWith({
    bool? isEnabled,
    bool? isUnlocked,
    bool? isBiometricEnabled,
  }) {
    return PinLockState(
      isEnabled: isEnabled ?? this.isEnabled,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
    );
  }
}

@Riverpod(keepAlive: true)
class PinLockController extends _$PinLockController {
  @override
  Future<PinLockState> build() async {
    final repository = ref.read(pinLockRepositoryProvider);
    final isEnabled = await repository.isEnabled();
    final isBiometricEnabled =
        isEnabled ? await repository.isBiometricEnabled() : false;
    return PinLockState(
      isEnabled: isEnabled,
      isUnlocked: !isEnabled,
      isBiometricEnabled: isBiometricEnabled,
    );
  }

  void lockIfEnabled() {
    final current = state.value;
    if (current == null || !current.isEnabled) {
      return;
    }
    state = AsyncData(current.copyWith(isUnlocked: false));
  }

  void markUnlocked() {
    final current = state.value;
    if (current == null) {
      return;
    }
    state = AsyncData(current.copyWith(isUnlocked: true));
  }

  Future<void> onPinEnabled() async {
    state = const AsyncData(
      PinLockState(
        isEnabled: true,
        isUnlocked: true,
        isBiometricEnabled: false,
      ),
    );
  }

  Future<void> onPinDisabled() async {
    state = const AsyncData(
      PinLockState(
        isEnabled: false,
        isUnlocked: true,
        isBiometricEnabled: false,
      ),
    );
  }

  void onBiometricEnabledChanged(bool enabled) {
    final current = state.value;
    if (current == null) {
      return;
    }
    state = AsyncData(current.copyWith(isBiometricEnabled: enabled));
  }

  Future<String?> unlock(String pin) async {
    final result = await ref.read(verifyPinUseCaseProvider)(pin);
    return result.fold(
      (failure) => failure.message,
      (_) {
        markUnlocked();
        return null;
      },
    );
  }

  /// Returns an error message, or null on success or user cancellation (PIN fallback).
  Future<String?> unlockWithBiometric() async {
    final result = await ref.read(authenticateWithBiometricUseCaseProvider)();
    switch (result.outcome) {
      case BiometricAuthOutcome.success:
        markUnlocked();
        return null;
      case BiometricAuthOutcome.cancelled:
        return null;
      case BiometricAuthOutcome.failed:
      case BiometricAuthOutcome.unavailable:
        return result.message ?? 'Biometric authentication failed.';
    }
  }
}

@riverpod
bool pinLockNeedsUnlock(Ref ref) {
  final pinLock = ref.watch(pinLockControllerProvider);
  return pinLock.maybeWhen(
    data: (state) => state.needsUnlock,
    orElse: () => false,
  );
}
