import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mali_app/application/providers/pin_lock_providers.dart';
import 'package:mali_app/application/providers/pin_lock_store_providers.dart';
import 'package:mockito/mockito.dart';

import '../../unit/usecases_test.mocks.dart';

void main() {
  late MockIPinLockRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = MockIPinLockRepository();
    when(repository.isEnabled()).thenAnswer((_) async => true);
    when(repository.isBiometricEnabled()).thenAnswer((_) async => false);

    container = ProviderContainer(
      overrides: [
        pinLockRepositoryProvider.overrideWithValue(repository),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('lockIfEnabled is ignored while biometric prompt suppresses lock',
      () async {
    final state = await container.read(pinLockControllerProvider.future);
    expect(state.isUnlocked, isFalse);

    final controller = container.read(pinLockControllerProvider.notifier);
    controller.markUnlocked();
    expect(container.read(pinLockControllerProvider).value!.isUnlocked, isTrue);

    await controller.runWithLifecycleLockSuppressed(() async {
      controller.lockIfEnabled();
      expect(
        container.read(pinLockControllerProvider).value!.isUnlocked,
        isTrue,
      );
      expect(controller.isLifecycleLockSuppressed, isTrue);
    });

    expect(controller.isLifecycleLockSuppressed, isFalse);
    controller.lockIfEnabled();
    expect(container.read(pinLockControllerProvider).value!.isUnlocked, isFalse);
  });

  test('onPinEnabled keeps biometric preference from storage', () async {
    when(repository.isBiometricEnabled()).thenAnswer((_) async => true);

    await container.read(pinLockControllerProvider.future);
    final controller = container.read(pinLockControllerProvider.notifier);
    await controller.onPinEnabled();

    final state = container.read(pinLockControllerProvider).value!;
    expect(state.isEnabled, isTrue);
    expect(state.isUnlocked, isTrue);
    expect(state.isBiometricEnabled, isTrue);
  });
}
